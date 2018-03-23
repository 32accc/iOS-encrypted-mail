//
//  ComposeViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/15/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit

final class ComposeViewModelImpl : ComposeViewModel {
    
    enum RuntimeError : String, Error, CustomErrorVar {
        
        case no_address = "Can't find the public key for this address"
        
        var code: Int {
            get {
                return -1010
            }
        }
        
        var desc: String {
            get {
                return self.rawValue
            }
        }
        
        var reason: String {
            get {
                return self.rawValue
            }
        }
        
    }
    
    
    init(subject: String, body: String, files: [FileData], action : ComposeMessageAction!) {
        super.init()
        self.message = nil
        self.setSubject(subject)
        self.setBody(body)
        self.messageAction = action

        self.collectDraft(subject,
                          body: body,
                          expir: 0,
                          pwd: "",
                          pwdHit: "")
        self.updateDraft()
        
        for f in files {
            self.uploadAtt(f.data.toAttachment(self.message!, fileName: f.name, type: f.ext))
        }
        
    }
    
    init(msg: Message?, action : ComposeMessageAction!) {
        super.init()
        
        if msg == nil || msg?.location == MessageLocation.draft {
            self.message = msg
            self.setSubject(self.message?.title ?? "")
        }
        else
        {
            if msg?.managedObjectContext == nil {
                self.message = nil
            } else {
                self.message = msg?.copyMessage(action == ComposeMessageAction.forward)
                self.message?.action = action.rawValue as NSNumber?
                if action == ComposeMessageAction.reply || action == ComposeMessageAction.replyAll {
                    if let title = self.message?.title {
                        if !title.hasRe() {
                            let re = NSLocalizedString("Re:", comment: "Title")
                            self.message?.title = "\(re) \(title)"
                        }
                    }
                } else if action == ComposeMessageAction.forward {
                    if let title = self.message?.title {
                        if !title.hasFwd() {
                            let fwd = NSLocalizedString("Fwd:", comment: "Title")
                            self.message?.title = "\(fwd) \(title)"
                        }
                    }
                } else {
                }
            }
            //PMLog.D(message!);
        }
        
        self.setSubject(self.message?.title ?? "")
        self.messageAction = action
        self.updateContacts(msg?.location)
    }
    
    deinit {
        PMLog.D("ComposeViewModelImpl deinit")
    }
    
    fileprivate let k12HourMinuteFormat = "h:mm a"
    fileprivate let k24HourMinuteFormat = "HH:mm"
    private func using12hClockFormat() -> Bool {
        
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: Date())
        let amRange = dateString.range(of: formatter.amSymbol)
        let pmRange = dateString.range(of: formatter.pmSymbol)
        
        return !(pmRange == nil && amRange == nil)
    }
    
    override func uploadAtt(_ att: Attachment!) {
        sharedMessageDataService.uploadAttachment(att)
        self.updateDraft()
    }
    
    override func deleteAtt(_ att: Attachment!) {
        sharedMessageDataService.deleteAttachment(message?.messageID ?? "", att: att)
        self.updateDraft()
    }
    
    override func getAttachments() -> [Attachment]? {
        return self.message?.attachments.allObjects as? [Attachment]
    }
    
    override func updateAddressID(_ address_id: String) -> Promise<Void> {
        return async {
            guard let userinfo = sharedUserDataService.userInfo,
                let addr = userinfo.userAddresses.indexOfAddress(address_id),
                let key = addr.keys.first else {
                throw RuntimeError.no_address.toError()
            }
            
            if let atts = self.getAttachments() {
                for att in atts {
                    do {
                        guard let session = try att.sessionKey() else {
                            continue
                        }
                        guard let newKeyPack = try session.getPublicSessionKeyPackage(key.public_key)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) else {
                            continue
                        }
                        
                        att.keyPacket = newKeyPack
                        att.keyChanged = true
                    } catch {
                        
                    }
                }
                
                if let context = self.message?.managedObjectContext {
                    context.perform {
                        if let error = context.saveUpstreamIfNeeded() {
                            PMLog.D("error: \(error)")
                        }
                    }
                }
                
            }
            
            self.message?.addressID = address_id
            self.updateDraft()
        }
        
    }
    
    override func getAddresses() -> [Address] {
        return sharedUserDataService.userAddresses
    }
    
    override func getDefaultSendAddress() -> Address? {
        if self.message == nil {
            if let addr = sharedUserDataService.userAddresses.defaultSendAddress() {
                return addr
            }
        }
        return self.message?.defaultAddress
    }
    
    override func fromAddress() -> Address? {
        return self.message?.fromAddress
    }
    
    override func getCurrrentSignature(_ addr_id : String) -> String? {
        if let addr = sharedUserDataService.userAddresses.indexOfAddress(addr_id) {
            return addr.signature
        }
        return nil
    }
    
    override func hasAttachment() -> Bool {
        return true;
    }
    
    fileprivate func updateContacts(_ oldLocation : MessageLocation?)
    {
        if message != nil {
            switch messageAction!
            {
            case .newDraft, .forward, .newDraftFromShare:
                break;
            case .openDraft:
                let toContacts = self.toContacts(self.message!.recipientList)
                for cont in toContacts {
                    if !cont.isDuplicatedWithContacts(self.toSelectedContacts) {
                        self.toSelectedContacts.append(cont)
                    }
                }
                
                let ccContacts = self.toContacts(self.message!.ccList)
                for cont in ccContacts {
                    if  !cont.isDuplicatedWithContacts(self.ccSelectedContacts) {
                        self.ccSelectedContacts.append(cont)
                    }
                }
                let bccContacts = self.toContacts(self.message!.bccList)
                for cont in bccContacts {
                    if !cont.isDuplicatedWithContacts(self.bccSelectedContacts) {
                        self.bccSelectedContacts.append(cont)
                    }
                }
            case .reply:
                if oldLocation == .outbox {
                    let toContacts = self.toContacts(self.message!.recipientList)
                    for cont in toContacts {
                        self.toSelectedContacts.append(cont)
                    }
                } else {
                    var sender : ContactVO!
                    if let replyToContact = self.toContact(self.message!.replyTo ?? "") {
                        sender = replyToContact
                    } else {
                        if let newSender = self.toContact(self.message!.senderObject ?? "") {
                            sender = newSender
                        } else {
                            sender = ContactVO(id: "", name: self.message!.senderName, email: self.message!.senderAddress)
                        }
                    }
                    
                    self.toSelectedContacts.append(sender)
                }
            case .replyAll:
                if oldLocation == .outbox {
                    let toContacts = self.toContacts(self.message!.recipientList)
                    for cont in toContacts {
                        self.toSelectedContacts.append(cont)
                    }
                    let senderContacts = self.toContacts(self.message!.ccList)
                    for cont in senderContacts {
                        self.ccSelectedContacts.append(cont)
                    }
                } else {
                    let userAddress = sharedUserDataService.userAddresses
                    var sender : ContactVO!
                    if let replyToContact = self.toContact(self.message!.replyTo ?? "") {
                        sender = replyToContact
                    } else {
                        if let newSender = self.toContact(self.message!.senderObject ?? "") {
                            sender = newSender
                        } else {
                            sender = ContactVO(id: "", name: self.message!.senderName, email: self.message!.senderAddress)
                        }
                    }
                    
                    if  !sender.isDuplicated(userAddress) {
                        self.toSelectedContacts.append(sender)
                    }
                    
                    let toContacts = self.toContacts(self.message!.recipientList)
                    for cont in toContacts {
                        if  !cont.isDuplicated(userAddress) && !cont.isDuplicatedWithContacts(self.toSelectedContacts) {
                            self.toSelectedContacts.append(cont)
                        }
                    }
                    if self.toSelectedContacts.count <= 0 {
                        self.toSelectedContacts.append(sender)
                    }
                    let senderContacts = self.toContacts(self.message!.ccList)
                    for cont in senderContacts {
                        if  !cont.isDuplicated(userAddress) && !cont.isDuplicatedWithContacts(self.toSelectedContacts) {
                            self.ccSelectedContacts.append(cont)
                        }
                    }
                }
            }
        }
    }
    
    override func sendMessage() {
        
        self.updateDraft()
        sharedMessageDataService.send(self.message?.messageID)  { task, response, error in
            
        }
        
    }
    
    override func collectDraft(_ title: String, body: String, expir:TimeInterval, pwd:String, pwdHit:String) {
        self.setSubject(title)
        
        if message == nil || message?.managedObjectContext == nil {
            self.message = MessageHelper.messageWithLocation(MessageLocation.draft,
                                                             recipientList: toJsonString(self.toSelectedContacts),
                                                             bccList: toJsonString(self.bccSelectedContacts),
                                                             ccList: toJsonString(self.ccSelectedContacts),
                                                             title: self.subject,
                                                             encryptionPassword: "",
                                                             passwordHint: "",
                                                             expirationTimeInterval: expir,
                                                             body: body,
                                                             attachments: nil,
                                                             mailbox_pwd: sharedUserDataService.mailboxPassword!, //better to check nil later
                                                             inManagedObjectContext: sharedCoreDataService.mainManagedObjectContext!)
            self.message?.password = pwd
            self.message?.isRead = true
            self.message?.passwordHint = pwdHit
            self.message?.expirationOffset = Int32(expir)
            
        } else {
            self.message?.recipientList = toJsonString(self.toSelectedContacts)
            self.message?.ccList = toJsonString(self.ccSelectedContacts)
            self.message?.bccList = toJsonString(self.bccSelectedContacts)
            self.message?.title = self.subject
            self.message?.time = Date()
            self.message?.password = pwd
            self.message?.isRead = true
            self.message?.passwordHint = pwdHit
            self.message?.expirationOffset = Int32(expir)
            self.message?.setLabelLocation(.draft)
            MessageHelper.updateMessage(self.message!, expirationTimeInterval: expir, body: body, attachments: nil, mailbox_pwd: sharedUserDataService.mailboxPassword!)
            
            if let context = message!.managedObjectContext {
                context.perform {
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D(" error: \(error)")
                    }
                }
            }
        }
    }
    
    override func updateDraft() {
        sharedMessageDataService.saveDraft(self.message);
    }
    
    override func deleteDraft() {
        if let tmpLocation = self.message?.location {
            lastUpdatedStore.ReadMailboxMessage(tmpLocation)
        }
        sharedMessageDataService.deleteDraft(self.message);
    }
    
    override func markAsRead() {
        if message != nil {
            message?.isRead = true;
            if let context = message!.managedObjectContext {
                context.perform {
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D(" error: \(error)")
                    }
                }
            }
        }
    }
    
    override func getHtmlBody() -> String {
        //sharedUserDataService.signature
        let signature = self.getDefaultSendAddress()?.signature ?? "\(sharedUserDataService.signature)"
        
        let mobileSignature = sharedUserDataService.showMobileSignature ? "<div><br></div><div><br></div><div id=\"protonmail_mobile_signature_block\">\(sharedUserDataService.mobileSignature)</div>" : ""
        
        let defaultSignature = sharedUserDataService.showDefaultSignature ? "<div><br></div><div><br></div><div class=\"protonmail_signature_block\">\(signature)</div>" : ""
        
        let head = "<html><head></head><body>"
        let foot = "</body></html>"
        let htmlString = "\(defaultSignature) \(mobileSignature)"
        
        
        if let msgAction = messageAction {
            switch msgAction
            {
            case .openDraft:
                var body = ""
                do {
                    body = try message?.decryptBodyIfNeeded() ?? ""
                } catch let ex as NSError {
                    PMLog.D("getHtmlBody OpenDraft error : \(ex)")
                    body = self.message!.bodyToHtml()
                }
                
                body = body.stringByStrippingStyleHTML()
                body = body.stringByStrippingBodyStyle()
                body = body.stringByPurifyHTML()
                return body
                
            case .reply, .replyAll:
                
                var body = ""
                do {
                    body = try message!.decryptBodyIfNeeded() ?? ""
                } catch let ex as NSError {
                    PMLog.D("getHtmlBody OpenDraft error : \(ex)")
                    body = self.message!.bodyToHtml()
                }
                
                body = body.stringByStrippingStyleHTML()
                body = body.stringByStrippingBodyStyle()
                body = body.stringByPurifyHTML()
                let on = NSLocalizedString("On", comment: "Title")
                let at = NSLocalizedString("at", comment: "Title")
                let timeformat = using12hClockFormat() ? k12HourMinuteFormat : k24HourMinuteFormat
                let time : String! = message!.orginalTime?.formattedWith("'\(on)' EE, MMM d, yyyy '\(at)' \(timeformat)") ?? ""
                let sn : String! = (message?.managedObjectContext != nil) ? message!.senderContactVO.name : "unknow"
                let se : String! = message?.managedObjectContext != nil ? message!.senderContactVO.email : "unknow"
                
                var replyHeader = time + ", " + sn! + " &lt;<a href=\"mailto:" + se + "\" class=\"\">" + se + "</a>&gt;"
                replyHeader = replyHeader.stringByStrippingStyleHTML()
                replyHeader = replyHeader.stringByStrippingBodyStyle()
                replyHeader = replyHeader.stringByPurifyHTML()
                
                let w = NSLocalizedString("wrote:", comment: "Title")
                let sp = "<div><br><div><div><br></div>\(replyHeader) \(w)</div><blockquote class=\"protonmail_quote\" type=\"cite\"> "
                
                return " \(head) \(htmlString) \(sp) \(body)</blockquote> \(foot)"
            case .forward:
                let on = NSLocalizedString("On", comment: "Title")
                let at = NSLocalizedString("at", comment: "Title")
                let timeformat = using12hClockFormat() ? k12HourMinuteFormat : k24HourMinuteFormat
                let time = message!.orginalTime?.formattedWith("'\(on)' EE, MMM d, yyyy '\(at)' \(timeformat)") ?? ""
                
                let fwdm = NSLocalizedString("Forwarded message", comment: "Title")
                let from = NSLocalizedString("From:", comment: "Title")
                let dt = NSLocalizedString("Date:", comment: "Title")
                let sj = NSLocalizedString("Subject:", comment: "Title")
                let t = NSLocalizedString("To:", comment: "Title")
                let c = NSLocalizedString("Cc:", comment: "Title")
                var forwardHeader =
                "---------- \(fwdm) ----------<br>\(from) " + message!.senderContactVO.name + "&lt;<a href=\"mailto:" + message!.senderContactVO.email + "\" class=\"\">" + message!.senderContactVO.email + "</a>&gt;<br>\(dt) \(time)<br>\(sj) \(message!.title)<br>"
                
                if message!.recipientList != "" {
                    forwardHeader += "\(t) \(message!.recipientList.formatJsonContact(true))<br>"
                }
                
                if message!.ccList != "" {
                    forwardHeader += "\(c) \(message!.ccList.formatJsonContact(true))<br>"
                }
                forwardHeader += ""
                var body = ""
                
                do {
                    body = try message!.decryptBodyIfNeeded() ?? ""
                } catch let ex as NSError {
                    PMLog.D("getHtmlBody OpenDraft error : \(ex)")
                    body = self.message!.bodyToHtml()
                }
                
                body = body.stringByStrippingStyleHTML()
                body = body.stringByStrippingBodyStyle()
                body = body.stringByPurifyHTML()
                
                var sp = "<blockquote class=\"protonmail_quote\" type=\"cite\">\(forwardHeader)</div> "
                sp = sp.stringByStrippingStyleHTML()
                sp = sp.stringByStrippingBodyStyle()
                sp = sp.stringByPurifyHTML()
                
                return "\(head)\(htmlString)\(sp)\(body)\(foot)"
            case .newDraft:
                if !self.body.isEmpty {
                    let newhtmlString = "\(head) \(self.body!) \(htmlString) \(foot)"
                    self.body = ""
                    return newhtmlString
                } else {
                    if htmlString.trim().isEmpty {
                        let ret_body = "<div><br><div><div><br></div><div><br></div><div><br></div>" //add some space
                        return ret_body
                    }
                }
                return htmlString
            case .newDraftFromShare:
                if !self.body.isEmpty {
                    let newhtmlString = "\(head) \(self.body!) \(htmlString) \(foot)"
                    return newhtmlString
                } else {
                    if htmlString.trim().isEmpty {
                        let ret_body = "<div><br><div><div><br></div><div><br></div><div><br></div>" //add some space
                        return ret_body
                    }
                }
                return htmlString
            }

        }
        //when goes here , need log error
        return htmlString
    }
}

extension ComposeViewModelImpl {
    func toJsonString(_ contacts : [ContactVO]) -> String {
        
        var out : [[String : String]] = [[String : String]]();
        for contact in contacts {
            let to : [String : String] = ["Name" : contact.name ?? "", "Address" : contact.email ?? ""]
            out.append(to)
        }
        
        let bytes : Data = try! JSONSerialization.data(withJSONObject: out, options: JSONSerialization.WritingOptions())
        let strJson : String = NSString(data: bytes, encoding: String.Encoding.utf8.rawValue)! as String
        
        return strJson
    }
    func toContacts(_ json : String) -> [ContactVO] {
        
        var out : [ContactVO] = [ContactVO]();
        
        let recipients : [[String : String]] = json.parseJson()!
        for dict:[String : String] in recipients {
            out.append(ContactVO(id: "", name: dict["Name"], email: dict["Address"]))
        }
        return out
    }
    
    func toContact(_ json : String) -> ContactVO? {
        var out : ContactVO? = nil
        let recipients : [String : String] = self.parse(json)
        
        let name = recipients["Name"] ?? ""
        let address = recipients["Address"] ?? ""
        
        if !address.isEmpty {
            out = ContactVO(id: "", name: name, email: address)
        }
        return out
    }
    
    func parse (_ json : String) -> [String:String] {
        if json.isEmpty {
            return ["" : ""];
        }
        do {
            let data : Data! = json.data(using: String.Encoding.utf8)
            let decoded = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:String]
            return decoded ?? ["" : ""]
        } catch {
            PMLog.D(" func parseJson() -> error error \(error)")
        }
        return ["":""]
    }
}



