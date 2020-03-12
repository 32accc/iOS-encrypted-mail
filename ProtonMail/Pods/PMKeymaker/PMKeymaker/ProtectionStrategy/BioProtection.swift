//
//  BioProtection.swift
//  ProtonMail - Created on 18/10/2018.
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
import Security
import EllipticCurveKeyPair

private enum GenericBioProtectionConstants {
    static var privateLabelKey = String(describing: "BioProtection") + ".private"
    static var publicLabelKey = String(describing: "BioProtection") + ".public"
    static var legacyLabelKey = String(describing: "BioProtection") + ".legacy"
}

public struct GenericBioProtection<SUBTLE: SubtleProtocol>: ProtectionStrategy {
    private typealias Constants = GenericBioProtectionConstants
    public let keychain: Keychain
    
    public init(keychain: Keychain) {
        self.keychain = keychain
    }
    
    private static func makeAsymmetricEncryptor(in keychain: Keychain) -> EllipticCurveKeyPair.Manager {
        let publicAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAlwaysThisDeviceOnly, flags: [.userPresence, .privateKeyUsage])
        let privateAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, flags: [.userPresence, .privateKeyUsage])
        let config = EllipticCurveKeyPair.Config(publicLabel: Constants.publicLabelKey,
                                                  privateLabel: Constants.privateLabelKey,
                                                  operationPrompt: "MUCH IMPORTANT SO NEED",
                                                  publicKeyAccessControl: publicAccessControl,
                                                  privateKeyAccessControl: privateAccessControl,
                                                  publicKeyAccessGroup: keychain.accessGroup,
                                                  privateKeyAccessGroup: keychain.accessGroup,
                                                  token: .secureEnclave)
        return EllipticCurveKeyPair.Manager(config: config)
    }
    
    // for iOS older than 10.3 - not capable of elliptic curve encryption
    private static func makeSymmetricEncryptor(in keychain: Keychain) -> Key {
        guard let key = keychain.data(forKey: Constants.legacyLabelKey) else {
            let oldAccessibility = keychain.accessibility
            let oldAuthPolicy = keychain.authenticationPolicy
            
            keychain.switchAccessibilitySettings(.afterFirstUnlockThisDeviceOnly, authenticationPolicy: .userPresence)
            
            let ethemeralKey = GenericBioProtection.generateRandomValue(length: 32)
            keychain.set(Data(ethemeralKey), forKey: Constants.legacyLabelKey)

            keychain.switchAccessibilitySettings(oldAccessibility, authenticationPolicy: oldAuthPolicy)
            return ethemeralKey
        }
        return key.bytes
    }
    
    public func lock(value: Key) throws {
        let locked = try GenericLocked<Key, SUBTLE>(clearValue: value) { cleartext -> Data in
            if #available(iOS 10.3, *) {
                let encryptor = GenericBioProtection.makeAsymmetricEncryptor(in: self.keychain)
                return try encryptor.encrypt(Data(cleartext))
            } else {
                let ethemeral = GenericBioProtection.makeSymmetricEncryptor(in: self.keychain)
                let locked = try GenericLocked<Key, SUBTLE>(clearValue: cleartext, with: ethemeral)
                return locked.encryptedValue
            }
        }
        
        GenericBioProtection.saveCyphertext(locked.encryptedValue, in: self.keychain)
    }
    
    public func unlock(cypherBits: Data) throws -> Key {
        let locked = GenericLocked<Key, SUBTLE>(encryptedValue: cypherBits)
        let cleardata = try locked.unlock { cyphertext -> Key in
            if #available(iOS 10.3, *) {
                let encryptor = GenericBioProtection.makeAsymmetricEncryptor(in: self.keychain)
                return try encryptor.decrypt(cyphertext).bytes
            } else {
                let ethemeral = GenericBioProtection.makeSymmetricEncryptor(in: self.keychain)
                return try locked.unlock(with: ethemeral)
            }
        }
        
        return cleardata
    }
    
    public static func removeCyphertext(from keychain: Keychain) {
        (self as ProtectionStrategy.Type).removeCyphertext(from: keychain)
        try? GenericBioProtection.makeAsymmetricEncryptor(in: keychain).deleteKeyPair()
        keychain.remove(forKey: Constants.legacyLabelKey)
    }
}
