//
//  NonExpandedHeaderViewModel.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import PromiseKit
import ProtonCore_UIFoundations

class NonExpandedHeaderViewModel {

    var reloadView: (() -> Void)?

    var senderEmail: String { "\((message.sender?.email ?? ""))" }

    var initials: String { senderName.initials() }

    var originImage: UIImage? {
        let id = message.messageLocation?.labelID ?? labelId
        if let image = message.getLocationImage(in: id) {
            return image
        }
        return message.isCustomFolder ? IconProvider.folder : nil
    }

    var time: String {
        guard let date = message.time else { return .empty }
        return PMDateFormatter
            .shared
            .string(from: date, weekStart: user.userinfo.weekStartValue)
    }

    lazy var recipient: String = {
        let lists = self.message.ccList + self.message.bccList + self.message.toList
        let groupNames = lists
            .compactMap({ $0 as? ContactGroupVO })
            .map { recipient -> String in
                let groupName = recipient.contactTitle
                let group = groupContacts.first(where: { $0.contactTitle == groupName })
                let count = group?.contactCount ?? 0
                let name = "\(groupName) (\(recipient.contactCount)/\(count))"
                return name
            }
        let receiver = lists
            .compactMap { item -> String? in
                guard let contact = item as? ContactVO else {
                    return nil
                }
                guard let name = user.contactService.getName(of: contact.email) else {
                    let name = contact.displayName ?? ""
                    return name.isEmpty ? contact.displayEmail : name
                }
                return name
            }
        let result = groupNames + receiver
        let name = result.isEmpty ? "" : result.asCommaSeparatedList(trailingSpace: true)
        let recipients = name.isEmpty ? LocalString._undisclosed_recipients : name
        return recipients
    }()

    var tags: [TagUIModel] {
        message.tagUIModels
    }

    var senderContact: ContactVO?

    let user: UserManager

    private(set) var message: MessageEntity {
        didSet {
            reloadView?()
        }
    }

    lazy var groupContacts: [ContactGroupVO] = { [unowned self] in
        self.user.contactGroupService.getAllContactGroupVOs()
    }()

    private let labelId: LabelID

    lazy var senderName: String = {
        guard let senderInfo = self.message.sender else {
            assert(false, "Sender with no name or address")
            return ""
        }
        guard let contactName = user.contactService.getName(of: senderInfo.email) else {
            return senderInfo.name.isEmpty ? senderInfo.email : senderInfo.name
        }
        return contactName
    }()

    init(labelId: LabelID, message: MessageEntity, user: UserManager) {
        self.labelId = labelId
        self.message = message
        self.user = user
    }

    func messageHasChanged(message: MessageEntity) {
        self.message = message
    }

}
