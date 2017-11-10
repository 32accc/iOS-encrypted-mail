//
//  PasswordUtils.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/28/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation

enum PasswordError: Error {
    case hashEmpty
    case hashEmptyEncode
    case hashSizeWrong
}

final class PasswordUtils {
    static func getHashedPwd(_ authVersion: Int , password: String, username: String, decodedSalt : Data, decodedModulus : Data) -> Data? {
        var hashedPassword : Data?
        switch authVersion {
        case 0:
            hashedPassword = PasswordUtils.hashPasswordVersion0(password, username: username, modulus: decodedModulus)
            break
        case 1:
            hashedPassword = PasswordUtils.hashPasswordVersion1(password, username: username, modulus: decodedModulus)
            break
        case 2:
            hashedPassword = PasswordUtils.hashPasswordVersion2(password, username: username, modulus: decodedModulus)
            break
        case 3:
            hashedPassword = PasswordUtils.hashPasswordVersion3(password, salt: decodedSalt, modulus: decodedModulus)
            break
        case 4:
            hashedPassword = PasswordUtils.hashPasswordVersion4(password, salt: decodedSalt, modulus: decodedModulus)
            break
        default: break
        }
        return hashedPassword
    }
    
    
    static func CleanUserName(_ username : String) -> String {
        return username.preg_replace("_|\\.|-", replaceto: "").lowercased()
    }
    
    fileprivate static func bcrypt(_ password :String, salt :String) throws -> String {
        let real_salt = "$2a$10$" + salt
        let out_hash = PMNBCrypt(password: password, salt: real_salt)
        if !out_hash.isEmpty {
            let size = out_hash.characters.count
            if size > 4 {
                let index = out_hash.characters.index(out_hash.startIndex, offsetBy: 4)
                return "$2y$" + String(out_hash[index...])
            }
        }
        
        //backup plan when native bcrypt return empty string
        if let out = JKBCrypt.hashPassword(password, withSalt: real_salt), !out.isEmpty {
            let size = out.characters.count
            if size > 4 {
                let index = out.characters.index(out.startIndex, offsetBy: 4)
                return "$2y$" + String(out[index...])
            } else {
                throw PasswordError.hashSizeWrong
            }
        }
        throw PasswordError.hashEmpty
    }
    
    fileprivate static func bcrypt_byte(_ password :String, salt :String) throws -> Data? {
        let b = try bcrypt(password, salt: salt)
        if let stringData = b.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            return stringData
        }
        throw PasswordError.hashEmptyEncode
    }
    
    fileprivate static func bcrypt_string(_ password :String, salt :String) throws -> String {
        let b = try bcrypt(password, salt: salt)
        return b
    }
    
    
    static func expandHash(_ input : Data) -> Data {
        return PMNSrpClient.expandHash(input);
    }
    
    static func getMailboxPassword(_ password : String, salt : Data) -> String {
        let byteArray = NSMutableData()
        byteArray.append(salt)
        let source = NSData(data: byteArray as Data) as Data
        let encodedSalt = JKBCrypt.based64DotSlash(source)
        do {
            let out = try bcrypt_string(password, salt: encodedSalt)
            let index = out.characters.index(out.startIndex, offsetBy: 29)
            let outStr = String(out[index...])
            return outStr
        } catch PasswordError.hashEmpty {
            // check error
        } catch PasswordError.hashSizeWrong {
            // check error
        } catch {
            // check error
        }
        return ""
        
    }
    
    static func hashPasswordVersion4(_ password : String, salt : Data, modulus : Data) -> Data? {
        return hashPasswordVersion3(password, salt: salt, modulus: modulus);
    }
    
    static func hashPasswordVersion3(_ password : String, salt : Data, modulus : Data) -> Data? {
        let byteArray = NSMutableData()
        byteArray.append(salt)
        if let encodedSalt = "proton".data(using: String.Encoding.utf8, allowLossyConversion: false) {
            byteArray.append(encodedSalt)
        }
        
        let source = NSData(data: byteArray as Data) as Data
        let encodedSalt = JKBCrypt.based64DotSlash(source)
        
        do {
            if let out = try bcrypt_byte(password, salt: encodedSalt) {
                let outArray = NSMutableData()
                outArray.append(out)
                outArray.append(modulus)
                return expandHash(NSData(data: outArray as Data) as Data)
            }
        } catch PasswordError.hashEmpty {
            // check error
        } catch PasswordError.hashSizeWrong {
            // check error
        } catch {
            // check error
        }
        return nil
    }

    static func hashPasswordVersion2(_ password : String, username : String, modulus : Data) -> Data? {
        return hashPasswordVersion1(password, username: CleanUserName(username), modulus: modulus);
    }
    
    static func hashPasswordVersion1(_ password : String, username : String, modulus : Data) -> Data? {
        let un = username.lowercased()
        let salt = un.md5
        do {
            if let out = try bcrypt_byte(password, salt: salt) {
                let byteArray = NSMutableData()
                byteArray.append(out)
                byteArray.append(modulus)
                return expandHash(NSData(data: byteArray as Data) as Data)
            }
        } catch PasswordError.hashEmpty {
            // check error
        } catch PasswordError.hashSizeWrong {
            // check error
        } catch {
            // check error
        }
        return nil
    }
    
    static func hashPasswordVersion0(_ password : String,   username : String,  modulus: Data ) -> Data? {
        //need check password size
        if let prehashed = password.sha512_byte {
            let encoded = prehashed.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            return hashPasswordVersion1(encoded, username: username, modulus: modulus);
        }
        return nil
    }
    
}
