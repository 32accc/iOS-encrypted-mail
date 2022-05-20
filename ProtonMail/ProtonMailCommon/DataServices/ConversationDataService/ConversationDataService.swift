//
//  ConversationDataService.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import CoreData
import Foundation
import ProtonCore_Services

enum ConversationError: Error {
    case emptyConversationIDS
    case emptyLabel
}

protocol ConversationProvider: AnyObject {
    // MARK: - Collection fetching
    func fetchConversationCounts(addressID: String?, completion: ((Result<Void, Error>) -> Void)?)
    func fetchConversations(for labelID: LabelID,
                            before timestamp: Int,
                            unreadOnly: Bool,
                            shouldReset: Bool,
                            completion: ((Result<Void, Error>) -> Void)?)
    func fetchConversations(with conversationIDs: [ConversationID], completion: ((Result<Void, Error>) -> Void)?)
    // MARK: - Single item fetching
    func fetchConversation(with conversationID: ConversationID, includeBodyOf messageID: MessageID?, callOrigin: String?, completion: ((Result<Conversation, Error>) -> Void)?)
    // MARK: - Operations
    func deleteConversations(with conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?)
    func markAsRead(conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?)
    func markAsUnread(conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?)
    func label(conversationIDs: [ConversationID],
               as labelID: LabelID,
               isSwipeAction: Bool,
               completion: ((Result<Void, Error>) -> Void)?)
    func unlabel(conversationIDs: [ConversationID],
                 as labelID: LabelID,
                 isSwipeAction: Bool,
                 completion: ((Result<Void, Error>) -> Void)?)
    func move(conversationIDs: [ConversationID],
              from previousFolderLabel: LabelID,
              to nextFolderLabel: LabelID,
              isSwipeAction: Bool,
              completion: ((Result<Void, Error>) -> Void)?)
    // MARK: - Clean up
    func cleanAll()
    // MARK: - Local for legacy reasons
    func fetchLocalConversations(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Conversation]
    func fetchConversation(by conversationID: ConversationID) -> ConversationEntity?
    func findConversationIDsToApplyLabels(conversations: [ConversationEntity], labelID: LabelID) -> [ConversationID]
    func findConversationIDSToRemoveLabels(conversations: [ConversationEntity],
                                                   labelID: LabelID) -> [ConversationID]
}

final class ConversationDataService: Service, ConversationProvider {
    let apiService: APIService
    let userID: UserID
    let contextProvider: CoreDataContextProviderProtocol
    let labelDataService: LabelsDataService
    let lastUpdatedStore: LastUpdatedStoreProtocol
    private(set) weak var eventsService: EventsFetching?
    private weak var viewModeDataSource: ViewModeDataSource?
    private weak var queueManager: QueueManager?
    let undoActionManager: UndoActionManagerProtocol

    init(api: APIService,
         userID: UserID,
         contextProvider: CoreDataContextProviderProtocol,
         labelDataService: LabelsDataService,
         lastUpdatedStore: LastUpdatedStoreProtocol,
         eventsService: EventsFetching,
         undoActionManager: UndoActionManagerProtocol,
         viewModeDataSource: ViewModeDataSource?,
         queueManager: QueueManager?) {
        self.apiService = api
        self.userID = userID
        self.contextProvider = contextProvider
        self.labelDataService = labelDataService
        self.lastUpdatedStore = lastUpdatedStore
        self.eventsService = eventsService
        self.viewModeDataSource = viewModeDataSource
        self.queueManager = queueManager
        self.undoActionManager = undoActionManager
    }
}

// MARK: - Clean up
extension ConversationDataService {
    func cleanAll() {
        let context = contextProvider.rootSavingContext
        context.performAndWait {
            let conversationFetch = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
            conversationFetch.predicate = NSPredicate(format: "%K == %@ AND %K == %@", Conversation.Attributes.userID, self.userID.rawValue, Conversation.Attributes.isSoftDeleted, NSNumber(false))
            if let conversations = try? context.fetch(conversationFetch) as? [NSManagedObject] {
                conversations.forEach { context.delete($0) }
            }

            let contextLabelFetch = NSFetchRequest<NSFetchRequestResult>(entityName: ContextLabel.Attributes.entityName)
            contextLabelFetch.predicate = NSPredicate(format: "%K == %@ AND %K == %@", ContextLabel.Attributes.userID, self.userID.rawValue, ContextLabel.Attributes.isSoftDeleted, NSNumber(false))
            if let contextlabels = try? context.fetch(contextLabelFetch) as? [NSManagedObject] {
                contextlabels.forEach { context.delete($0) }
            }

            _ = context.saveUpstreamIfNeeded()
        }
    }
}

extension ConversationDataService {
    func fetchLocalConversations(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Conversation] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K in %@", Conversation.Attributes.conversationID, selected)
        do {
            if let conversations = try context.fetch(fetchRequest) as? [Conversation] {
                return conversations
            }
        } catch {
        }
        return []
    }

    func fetchConversation(by conversationID: ConversationID) -> ConversationEntity? {
        guard let conversation = Conversation.conversationForConversationID(conversationID.rawValue, inManagedObjectContext: contextProvider.mainContext) else {
            return nil
        }
        return ConversationEntity(conversation)
    }

    func findConversationIDsToApplyLabels(conversations: [ConversationEntity], labelID: LabelID) -> [ConversationID] {
        var conversationIDsToApplyLabel: [ConversationID] = []
        let context = contextProvider.mainContext
        context.performAndWait {
            conversations.forEach { conversation in
                let messages = Message
                    .messagesForConversationID(conversation.conversationID.rawValue,
                                               inManagedObjectContext: context)
                let needToUpdate = messages?
                    .allSatisfy({ $0.contains(label: labelID.rawValue) }) == false
                if needToUpdate {
                    conversationIDsToApplyLabel.append(conversation.conversationID)
                }
            }
        }

        return conversationIDsToApplyLabel
    }

    func findConversationIDSToRemoveLabels(conversations: [ConversationEntity],
                                                   labelID: LabelID) -> [ConversationID] {
        var conversationIDsToRemove: [ConversationID] = []
        let context = contextProvider.mainContext
        context.performAndWait {
            conversations.forEach { conversation in
                let messages = Message
                    .messagesForConversationID(conversation.conversationID.rawValue,
                                               inManagedObjectContext: context)
                let needToUpdate = messages?
                    .allSatisfy({ !$0.contains(label: labelID.rawValue) }) == false
                if needToUpdate {
                    conversationIDsToRemove.append(conversation.conversationID)
                }
            }
        }
        return conversationIDsToRemove
    }
}
