//
//  OpenPGPExtension.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
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

import Foundation
import Crypto
import ProtonCore_Crypto
import ProtonCore_DataModel

// MARK: - OpenPGP String extension

extension String {
    func verifyMessage(verifier: [Data], binKeys: [Data], passphrase: String) throws -> ExplicitVerifyMessage {
        try Crypto().decryptVerifyNonOptional(encrypted: self, publicKey: verifier, privateKey: binKeys, passphrase: passphrase, verifyTime: CryptoGetUnixTime())
    }

    func verifyMessage(verifier: [Data], userKeys: [Data], keys: [Key], passphrase: String) throws -> ExplicitVerifyMessage? {
        var firstError: Error?
        for key in keys {
            do {
                let addressKeyPassphrase = try MailCrypto.getAddressKeyPassphrase(userKeys: userKeys, passphrase: passphrase, key: key)
                let message = try Crypto().decryptVerifyNonOptional(encrypted: self,
                                                                    publicKey: verifier,
                                                                    privateKey: key.privateKey,
                                                                    passphrase: addressKeyPassphrase,
                                                                    verifyTime: CryptoGetUnixTime())
                return message
            } catch let error {
                if firstError == nil {
                    firstError = error
                }
            }
        }
        if let error = firstError {
            throw error
        }
        return nil
    }

    func encrypt(withKey key: Key, userKeys: [Data], mailbox_pwd: String) throws -> String {
        let addressKeyPassphrase = try MailCrypto.getAddressKeyPassphrase(userKeys: userKeys,
                                                                          passphrase: mailbox_pwd,
                                                                          key: key)
        return try Crypto().encryptNonOptional(plainText: self,
                                               publicKey: key.publicKey,
                                               privateKey: key.privateKey,
                                               passphrase: addressKeyPassphrase)
    }
}
