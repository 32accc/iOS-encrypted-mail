// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCoreDoh
import ProtonCoreEnvironment

struct BackendConfiguration {
    typealias Environment = ProtonCoreEnvironment.Environment

    static let shared = BackendConfiguration()

    let environment: Environment

    var doh: DoH {
        environment.doh
    }

    var isProduction: Bool {
        environment == .mailProd
    }

    init(
        launchArguments: [String] = ProcessInfo.processInfo.arguments,
        environmentVariables: [String: String] = ProcessInfo.processInfo.environment,
        isDebugOrEnterprise: () -> Bool = { Application.isDebugOrEnterprise },
        configurationCache: BackendConfigurationCacheProtocol = BackendConfigurationCache()
    ) {
        environment = .custom("account.kendrick.proton.black")
       SystemLogger.log(message: "Environment: \(environment.doh.defaultHost)", category: .appLifeCycle)
    }
}

extension BackendConfiguration {
    enum EnvironmentVariableKeys {
        static let backendApiDomain = "MAIL_APP_API_DOMAIN"
    }
}
