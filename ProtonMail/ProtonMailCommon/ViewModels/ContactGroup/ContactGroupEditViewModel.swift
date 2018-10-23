//
//  ContactGroupEditViewModel.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/21.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import PromiseKit

protocol ContactGroupEditViewControllerDelegate: class {
    func update()
}

enum ContactGroupEditError: Error
{
    case noEmailInGroup
    case noNameForGroup
    case noContactGroupID
    
    case NSSetConversionToEmailArrayFailure
    case NSSetConversionToEmailSetFailure
    
    case addFailed
    case updateFailed
    
    case cannotGetCoreDataContext
}

extension ContactGroupEditError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noEmailInGroup:
            return LocalString._contact_groups_no_email_selected
        case .noNameForGroup:
            return LocalString._contact_groups_no_name_entered
        case .noContactGroupID:
            // TODO: localization
            return NSLocalizedString("No group ID is returned from the contact group API",
                                     comment: "Contact group no ID")
        case .NSSetConversionToEmailArrayFailure:
            // TODO: localization
            return NSLocalizedString("Can't convert NSSet to array of Email",
                                     comment: "Contact group NSSet to array conversion failed")
        case .NSSetConversionToEmailSetFailure:
            // TODO: localization
            return NSLocalizedString("Can't convert NSSet to Set of Email",
                                     comment: "Contact group NSSet to Set conversion failed")
        case .addFailed:
            return LocalString._contact_groups_api_add_error
        case .updateFailed:
            return LocalString._contact_groups_api_update_error
        case .cannotGetCoreDataContext:
            return LocalString._cannot_get_coredata_context
        }
    }
}

enum ContactGroupEditTableCellType
{
    case manageContact
    case email
    case deleteGroup
    case error
}

struct ContactGroupData
{
    var ID: String?
    var name: String?
    var color: String
    let originalEmailIDs: NSSet
    var emailIDs: NSMutableSet
    
    init(ID: String?,
         name: String?,
         color: String?,
         emailIDs: NSSet)
    {
        self.ID = ID
        self.name = name
        self.color = color ?? ColorManager.getRandomColor()
        self.originalEmailIDs = emailIDs
        self.emailIDs = NSMutableSet(set: emailIDs)
    }
}

protocol ContactGroupEditViewModel {
    // delegate
    var delegate: ContactGroupEditViewControllerDelegate? { get set }
    
    // set operations
    func setName(name: String)
    func setEmails(emails: NSSet)
    func setColor(newColor: String)
    
    func removeEmail(emailID: String)
    
    // get operations
    func getViewTitle() -> String
    func getName() -> String
    func getContactGroupID() -> String?
    func getColor() -> String
    func getEmails() -> NSSet
    func getSectionTitle(for: Int) -> String
    
    // create and edit
    func saveDetail() -> Promise<Void>
    
    // delete
    func deleteContactGroup() -> Promise<Void>
    
    // table operation
    func getTotalSections() -> Int
    func getTotalRows(for section: Int) -> Int
    func getCellType(at indexPath: IndexPath) -> ContactGroupEditTableCellType
    func getEmail(at indexPath: IndexPath) -> (String, String, String)
}
