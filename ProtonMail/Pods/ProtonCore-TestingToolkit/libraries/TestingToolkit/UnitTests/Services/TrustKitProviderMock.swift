//
//  TrustKitProviderMock.swift
//  ProtonCore-TestingToolkit - Created on 16.02.2022.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
#if canImport(ProtonCoreTestingToolkitUnitTestsCore)
import ProtonCoreTestingToolkitUnitTestsCore
#endif
import TrustKit
import ProtonCoreServices

public final class TrustKitProviderMock: TrustKitProvider {

    public init() {}

    @PropertyStub(\TrustKitProvider.noTrustKit, initialGet: true) public var noTrustKitStub
    public var noTrustKit: Bool { noTrustKitStub() }
    @PropertyStub(\TrustKitProvider.trustKit, initialGet: nil) public var trustKitStub
    public var trustKit: TrustKit? { trustKitStub() }
}
