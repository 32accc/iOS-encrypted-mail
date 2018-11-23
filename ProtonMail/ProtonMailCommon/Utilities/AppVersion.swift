//
//  AppVersion.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import Keymaker
import Crypto
import CoreData

struct AppVersion {
    typealias MigrationBlock = ()->Void

    private(set) var string: String
    private var numbers: Array<Int>
    private var migration: MigrationBlock?
    private var model: NSManagedObjectModel?
    private var modelUrl: URL?
    private var modelName: String?
    
    // TODO: CAN WE IMPTOVE THIS API?
    init(_ string: String,
         modelName: String? = nil, // every known should have
         migration: MigrationBlock? = nil) // every known should have
    {
        self.numbers = string.components(separatedBy: CharacterSet.punctuationCharacters.union(CharacterSet.whitespaces)).compactMap { Int($0) }
        self.string = self.numbers.map(String.init).joined(separator: ".")
        self.migration = migration
        
        if let modelName = modelName,
            let modelUrl = CoreDataService.modelBundle.url(forResource: modelName, withExtension: "mom"),
            let model = NSManagedObjectModel(contentsOf: modelUrl)
        {
            self.modelName = modelName
            self.modelUrl = modelUrl
            self.model = model
        }
    }
}

extension AppVersion {
    static var current: AppVersion = {
        let filenames = CoreDataService.modelBundle.urls(forResourcesWithExtension: "mom", subdirectory: nil)
        let versionsWithChangesInModel = filenames?.compactMap { AppVersion($0.lastPathComponent) }.sorted()
        // by convention, model name corresponds with the version it was released in
        let latestVersionWithModelUpdate = versionsWithChangesInModel?.last?.string ?? AppVersion.firstVersionWithMigratorReleased.modelName!
        return AppVersion(Bundle.main.appVersion, modelName: latestVersionWithModelUpdate)
    }()
    static var firstVersionWithMigratorReleased = AppVersion("1.12.0", modelName: "1.12.0")
    static var lastVersionBeforeMigratorWasReleased = AppVersion("1.11.1", modelName: "ProtonMail")
    static var lastMigratedTo: AppVersion {
        get {
            // on first launch after install we're setting this value to .current
            // then if there is no value in UserDefaults means it's the first time user updated to a version with migrator implemented
            // and we should run all the migrations we have since first migrator
            guard !self.isFirstRun() else {
                return self.current
            }
            guard let string = UserDefaultsSaver<String>(key: Keys.lastMigratedToVersion).get(),
                let modelName = UserDefaultsSaver<String>(key: Keys.lastMigratedToModel).get() else
            {
                return AppVersion.lastVersionBeforeMigratorWasReleased
            }
            return AppVersion(string, modelName: modelName)
        }
        set {
            UserDefaultsSaver(key: Keys.lastMigratedToVersion).set(newValue: newValue.string)
            if let modelName = newValue.modelName {
                UserDefaultsSaver(key: Keys.lastMigratedToModel).set(newValue: modelName)
            }
        }
    }

    // methods
    
    static internal func migrate() {
        let knownVersions = [self.v1_12_0].sorted()
        let shouldMigrateTo = knownVersions.filter { $0 > self.lastMigratedTo && $0 <= self.current }
        
        var previousModel = self.lastMigratedTo.model!
        var previousUrl = CoreDataService.dbUrl
        
        shouldMigrateTo.forEach { nextKnownVersion in
            nextKnownVersion.migration?()
            
            // core data
            
            guard lastMigratedTo.modelName != nextKnownVersion.modelName,
                let nextModel = nextKnownVersion.model else
            {
                self.lastMigratedTo = nextKnownVersion
                return
            }
            
            guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType,
                                                                                              at: previousUrl,
                                                                                              options: nil),
                !nextModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) else
            {
                previousModel = nextModel
                self.lastMigratedTo = nextKnownVersion
                return
            }
            
            let migrationManager = NSMigrationManager(sourceModel: previousModel, destinationModel: nextModel)
            guard let mappingModel = NSMappingModel(from: [Bundle.main], forSourceModel: previousModel, destinationModel: nextModel) else {
                assert(false, "No mapping model found but need one")
                previousModel = nextModel
                self.lastMigratedTo = nextKnownVersion
                return
            }
            
            let destUrl = FileManager.default.temporaryDirectoryUrl.appendingPathComponent(UUID().uuidString, isDirectory: false)
            try? migrationManager.migrateStore(from: previousUrl,
                                              sourceType: NSSQLiteStoreType,
                                              options: nil,
                                              with: mappingModel,
                                              toDestinationURL: destUrl,
                                              destinationType: NSSQLiteStoreType,
                                              destinationOptions: nil)
            previousUrl = destUrl
            previousModel = nextModel
            self.lastMigratedTo = nextKnownVersion
        }
        
        try? NSPersistentStoreCoordinator(managedObjectModel: previousModel).replacePersistentStore(at: CoreDataService.dbUrl,
                                                                                              destinationOptions: nil,
                                                                                              withPersistentStoreFrom: previousUrl,
                                                                                              sourceOptions: nil,
                                                                                              ofType: NSSQLiteStoreType)
    }
    
    static func isFirstRun() -> Bool {
        return SharedCacheBase.getDefault().object(forKey: UserDataService.Key.firstRunKey) == nil
    }
}

extension AppVersion {
    /*
     IMPORTANT: each of these migrations read legacy values and transform them into current ones, not passing thru middle version's migrators. Please mind that user can migrate from every one of prevoius version, not only from the latest!
    */
    
    static var v1_12_0 = AppVersion("1.12.0", modelName: "1.12.0") {        
        // UserInfo
        if let userInfo = SharedCacheBase.getDefault().customObjectForKey(DeprecatedKeys.UserDataService.userInfo) as? UserInfo {
            AppVersion.inject(userInfo: userInfo, into: sharedUserDataService)
        }
        
        // mailboxPassword
        if let triviallyProtectedMailboxPassword = sharedKeychain.keychain.string(forKey: DeprecatedKeys.UserDataService.mailboxPassword),
            let cleartextMailboxPassword = try? triviallyProtectedMailboxPassword.decrypt(withPwd: "$Proton$" + DeprecatedKeys.UserDataService.mailboxPassword)
        {
            sharedUserDataService.mailboxPassword = cleartextMailboxPassword
        }
        
        // AuthCredential
        if let credentialRaw = sharedKeychain.keychain.data(forKey: DeprecatedKeys.AuthCredential.keychainStore),
            let credential = NSKeyedUnarchiver.unarchiveObject(with: credentialRaw) as? AuthCredential
        {
            credential.storeInKeychain()
        }
        
        // MainKey
        let appLockMigration = DispatchGroup()
        var appWasLocked = false
        
        // via touch id
        if userCachedStatus.getShared().bool(forKey: DeprecatedKeys.UserCachedStatus.isTouchIDEnabled) {
            appWasLocked = true
            appLockMigration.enter()
            keymaker.activate(BioProtection()) { _ in appLockMigration.leave() }
        }
        
        // via pin
        if userCachedStatus.getShared().bool(forKey: DeprecatedKeys.UserCachedStatus.isPinCodeEnabled),
            let pin = sharedKeychain.keychain.string(forKey: DeprecatedKeys.UserCachedStatus.pinCodeCache)
        {
            appWasLocked = true
            appLockMigration.enter()
            keymaker.activate(PinProtection(pin: pin)) { _ in appLockMigration.leave() }
        }
        
        // and lock the app afterwards
        if appWasLocked {
            appLockMigration.notify(queue: .main) { keymaker.lockTheApp() }
        }
        
        // Clear up the old stuff on fresh installs also
        sharedKeychain.keychain.removeItem(forKey: DeprecatedKeys.UserDataService.password)
        sharedKeychain.keychain.removeItem(forKey: DeprecatedKeys.UserDataService.mailboxPassword)
        sharedKeychain.keychain.removeItem(forKey: DeprecatedKeys.UserCachedStatus.pinCodeCache)
        sharedKeychain.keychain.removeItem(forKey: DeprecatedKeys.AuthCredential.keychainStore)
        sharedKeychain.keychain.removeItem(forKey: DeprecatedKeys.UserCachedStatus.enterBackgroundTime)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserCachedStatus.isTouchIDEnabled)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserCachedStatus.isPinCodeEnabled)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserCachedStatus.isManuallyLockApp)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserCachedStatus.touchIDEmail)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserDataService.isRememberUser)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserDataService.userInfo)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserDataService.isRememberMailboxPassword)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.PushNotificationService.token)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.PushNotificationService.UID)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.PushNotificationService.badToken)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.PushNotificationService.badUID)
    }
}


extension AppVersion {
    enum Keys {
        static let lastMigratedToVersion = "lastMigratedToVersion"
        static let lastMigratedToModel = "lastMigratedToModel"
    }
    
    enum DeprecatedKeys {
        enum AuthCredential {
            static let keychainStore = "keychainStoreKey"
        }
        enum UserCachedStatus {
            static let pinCodeCache         = "pinCodeCache"
            static let enterBackgroundTime  = "enterBackgroundTime"
            static let isManuallyLockApp    = "isManuallyLockApp"
            static let isPinCodeEnabled     = "isPinCodeEnabled"
            static let isTouchIDEnabled     = "isTouchIDEnabled"
            static let touchIDEmail         = "touchIDEmail"
        }
        enum UserDataService {
            static let password                  = "passwordKey"
            static let mailboxPassword           = "mailboxPasswordKey"
            static let isRememberUser            = "isRememberUserKey"
            static let userInfo                  = "userInfoKey"
            static let isRememberMailboxPassword = "isRememberMailboxPasswordKey"
        }
        enum PushNotificationService {
            static let token    = "DeviceTokenKey"
            static let UID      = "DeviceUID"
            
            static let badToken = "DeviceBadToken"
            static let badUID   = "DeviceBadUID"
        }
    }
}


extension AppVersion: Comparable, Equatable {
    static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        return lhs.numbers == rhs.numbers
    }
    
    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let maxCount: Int = max(lhs.numbers.count, rhs.numbers.count)
        
        func normalizer(_ input: Array<Int>) -> Array<Int> {
            var norm = input
            let zeros = Array<Int>(repeating: 0, count: maxCount - input.count)
            norm.append(contentsOf: zeros)
            return norm
        }
        
        let pairs = zip(normalizer(lhs.numbers), normalizer(rhs.numbers))
        for (l, r) in pairs {
            if l < r {
                return true
            } else if l > r {
                return false
            }
        }
        return false
    }
}
