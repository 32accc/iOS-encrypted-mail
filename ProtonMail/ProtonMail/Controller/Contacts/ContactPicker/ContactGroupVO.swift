//
//  ContactGroupVO.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/9/26.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

// contact group sub-selection
struct DraftEmailData: Hashable
{
    let name: String
    let email: String
    
    init(name: String, email: String) {
        self.name = name
        self.email = email
    }
}

class ContactGroupVO: NSObject, ContactPickerModelProtocol
{
    var modelType: ContactPickerModelState {
        get {
            return .contactGroup
        }
    }
    
    var ID: String
    var contactTitle: String
    var displayName: String?
    var displayEmail: String?
    var contactSubtitle: String?
    var contactImage: UIImage?
    var lock: UIImage?
    var hasPGPPined: Bool
    var hasNonePM: Bool
    
    func notes(type: Int) -> String {
        return ""
    }
    
    func setType(type: Int) { }
    
    func lockCheck(progress: () -> Void, complete: LockCheckComplete?) {}
    
    /*
     contact group subselection
     
     The contact information we can get from draft are name, email address, and group name
     
     So if the (name, email address) pair doesn't match any record inthe  current group,
     we will treat it as a new pair
     */
    typealias DraftEmailDataMultiSet = Dictionary<DraftEmailData, Int>
    private var selectedMembers: DraftEmailDataMultiSet // simulate multiset
    
    func getSelectedEmailsWithDetail() -> [(Group: String, Name: String, Address: String)]
    {
        var result: [(Group: String, Name: String, Address: String)] = []
        
        for member in selectedMembers {
            for _ in 0..<member.value {
                result.append((Group: self.contactTitle,
                               Name: member.key.name,
                               Address: member.key.email))
            }
        }
        
        return result
    }
    
    /**
     Get all email addresses
    */
    func getSelectedEmailAddresses() -> [String] {
        return self.selectedMembers.map{$0.key.email}
    }
    
    /**
     Get all DraftEmailData (the count will match)
    */
    func getSelectedEmailData() -> [DraftEmailData] {
        var result: [DraftEmailData] = []
        for member in selectedMembers {
            for _ in 0..<member.value {
                result.append(member.key)
            }
        }
        return result
    }
    
    /**
     Updates the selected members (completely overwrite)
    */
    func overwriteSelectedEmails(with newSelectedMembers: [DraftEmailData])
    {
        selectedMembers = DraftEmailDataMultiSet()
        for member in newSelectedMembers {
            if let count = selectedMembers[member] {
                selectedMembers.updateValue(count + 1, forKey: member)
            } else {
                selectedMembers[member] = 1
            }
        }
    }
    
    /**
     Select all emails from the contact group
     Notice: this method will clear all previous selections
    */
    func selectAllEmailFromGroup() {
        selectedMembers = DraftEmailDataMultiSet()
        
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let label = Label.labelForLabelName(contactTitle,
                                                   inManagedObjectContext: context) {
                for email in label.emails.allObjects as! [Email] {
                    let member = DraftEmailData.init(name: email.name,
                                                     email: email.email)
                    if let count = selectedMembers[member] {
                        selectedMembers.updateValue(count + 1, forKey: member)
                    } else {
                        selectedMembers[member] = 1
                    }
                }
            }
        }
    }
    
    private var groupSize: Int? = nil
    private var groupColor: String? = nil
    /**
     For the composer's autocomplete
     Note that groupSize and groupColor are cached!
     - Returns: the current group size and group color
    */
    func getContactGroupInfo() -> (total: Int, color: String) {
        if let size = groupSize, let color = groupColor {
            return (size, color)
        }
        
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let label = Label.labelForLabelName(contactTitle,
                                                   inManagedObjectContext: context) {
                groupColor = label.color
                groupSize = label.emails.count
                return (label.emails.count, label.color)
            }
        }
        
        return (0, ColorManager.defaultColor)
    }
    
    /**
     Calculates the group size, selected member count, and group color
     Information for composer collection view cell
    */
    func getGroupInformation() -> (memberSelected: Int, totalMemberCount: Int, groupColor: String) {
        let errorResponse = (0, 0, ColorManager.defaultColor)
        
        var emailMultiSet = DraftEmailDataMultiSet()
        var color = ""
        if let context = sharedCoreDataService.mainManagedObjectContext {
            // (1) get all email in the contact group
            if let label = Label.labelForLabelName(self.contactTitle,
                                                   inManagedObjectContext: context),
                let emails = label.emails.allObjects as? [Email] {
                color = label.color
                
                for email in emails {
                    let member = DraftEmailData.init(name: email.name,
                                                     email: email.email)
                    if let count = emailMultiSet[member] {
                        emailMultiSet.updateValue(count + 1, forKey: member)
                    } else {
                        emailMultiSet[member] = 1
                    }
                }
            } else {
                // TODO: handle error
                return errorResponse
            }
            
            // (2) get all that is NOT in the contact group, but is selected
            // Because we might have identical name-email pairs, we can't simply use a set
            // We use the frequency map of all name-email pairs,
            // and we 2a) add pairs that are not present in the emailMultiSet, or we 2b) update the
            // frequency counter of the emailMultiSet only if tmpMultiSet has a larger value
            for member in self.selectedMembers {
                if let count = emailMultiSet[member.key] {
                    // 2b)
                    emailMultiSet.updateValue(max(count, member.value), forKey: member.key)
                } else {
                    // 2a)
                    emailMultiSet[member.key] = member.value
                }
            }
            
            let memberSelected = self.selectedMembers.reduce(0, {x, y in
                return x + y.value
            })
            let totalMemberCount = emailMultiSet.reduce(0, {
                x, y in
                return x + y.value
            })
            
            return (memberSelected, totalMemberCount, color)
        } else {
            return errorResponse
        }
    }
    
    init(ID: String, name: String, groupSize: Int? = nil, color: String? = nil) {
        self.ID = ID
        self.contactTitle = name
        self.groupColor = color
        self.groupSize = groupSize
        
        self.displayName = nil
        self.displayEmail = nil
        self.contactSubtitle = ""
        self.contactImage = nil
        self.lock = nil
        self.hasPGPPined = false
        self.hasNonePM = false
        self.selectedMembers = DraftEmailDataMultiSet()
    }
    
    func equals(_ other: ContactPickerModelProtocol) -> Bool {
        return self.isEqual(other)
    }
}
