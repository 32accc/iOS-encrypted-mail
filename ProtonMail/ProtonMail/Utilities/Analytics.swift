//
//  Analytics.swift
//  ProtonMail - Created on 30/11/2018.
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
import Sentry

class Analytics {
    typealias Event = Sentry.Event
    static var shared = Analytics()
    
    private var sentryEndpoint: String {
        #if Enterprise
            return "https://3f5b27555fa64b519002266dcdc7744c@sentry.protontech.ch/25"
        #else
            return "https://bcbe8b2a026848c4b139df228d088072@sentry.protontech.ch/7"
        #endif
    }
    
    func setup() {
        SentrySDK.start { (options) in
            options.dsn = self.sentryEndpoint
            #if DEBUG
            options.debug = true
            #endif
        }
    }
    
    func logCustomEvent(customAttributes: Dictionary<String, Any>) {
        let event = Event(level: .debug)
        event.message = customAttributes.json()
        SentrySDK.capture(event: event)
    }
    
    func recordError(_ error: NSError) {
        let event = Event(level: .error)
        event.message = error.localizedDescription
        SentrySDK.capture(event: event)
    }
}
