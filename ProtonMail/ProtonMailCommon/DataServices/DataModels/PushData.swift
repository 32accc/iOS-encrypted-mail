//
//  PushData.swift
//  ProtonMail - Created on 12/13/17.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

enum RemoteNotificationType: String, Codable {
    case email
    case openUrl = "open_url"
}

/// This model represents the part of a remote push notification that comes encrypted
struct PushContent: Codable {
    let data: PushData
    let type: String?
    let version: Int?

    var remoteNotificationType: RemoteNotificationType? {
        guard let type = type else { return nil }
        return RemoteNotificationType(rawValue: type)
    }

    init(json: String) throws {
        self = try JSONDecoder().decode(PushContent.self, from: Data(json.utf8))
    }
}

struct PushData: Codable {
    let badge: Int
    let body: String
    let sender: Sender
    let messageId: String
    let url: URL?
    // Unused on iOS fields:
    //    let title: String
    //    let subtitle: String
    //    let vibrate: Int
    //    let sound: Int
    //    let largeIcon: String
    //    let smallIcon: String
}
