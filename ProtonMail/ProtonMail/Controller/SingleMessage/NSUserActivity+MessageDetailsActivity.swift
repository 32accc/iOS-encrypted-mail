//
//  NSUserActivity+MessageDetailsActivity.swift
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

import Foundation

extension NSUserActivity {

    static func messageDetailsActivity(messageId: MessageID) -> NSUserActivity {
        let activity = NSUserActivity(activityType: "Handoff.Message")
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = false
        activity.isEligibleForPublicIndexing = false
        if #available(iOS 12.0, *) {
            activity.isEligibleForPrediction = false
        }

        let deeplink = DeepLink(String(describing: MenuViewController.self))
        deeplink.append(.init(name: String(describing: MailboxViewController.self), value: Message.Location.inbox))
        deeplink.append(.init(name: String(describing: SingleMessageViewController.self), value: messageId.rawValue))

        if let deeplinkData = try? JSONEncoder().encode(deeplink) {
            activity.addUserInfoEntries(from: ["deeplink": deeplinkData])
        }

        return activity
    }

}
