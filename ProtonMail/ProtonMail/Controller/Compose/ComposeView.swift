//
//  ComposeView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//
import Foundation
import UIKit
import Masonry

protocol ComposeViewDelegate: class {
    func composeViewWillPresentSubview()
    func composeViewWillDismissSubview()
    
    func ComposeViewDidSizeChanged(_ size: CGSize, showPicker: Bool)
    func ComposeViewDidOffsetChanged(_ offset: CGPoint)
    func composeViewDidTapNextButton(_ composeView: ComposeView)
    func composeViewDidTapEncryptedButton(_ composeView: ComposeView)
    func composeViewDidTapAttachmentButton(_ composeView: ComposeView)
    
    func composeView(_ composeView: ComposeView, didAddContact contact: ContactPickerModelProtocol, toPicker picker: ContactPicker)
    func composeView(_ composeView: ComposeView, didRemoveContact contact: ContactPickerModelProtocol, fromPicker picker: ContactPicker)
    
    func composeViewHideExpirationView(_ composeView: ComposeView)
    func composeViewCancelExpirationData(_ composeView: ComposeView)
    func composeViewDidTapExpirationButton(_ composeView: ComposeView)
    func composeViewCollectExpirationData(_ composeView: ComposeView)
    
    func composeViewPickFrom(_ composeView: ComposeView)

    func lockerCheck(model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?)
}

protocol ComposeViewDataSource: class {
    func composeViewContactsModelForPicker(_ composeView: ComposeView, picker: ContactPicker) -> [ContactPickerModelProtocol]
    func composeViewSelectedContactsForPicker(_ composeView: ComposeView, picker: ContactPicker) -> [ContactPickerModelProtocol]
}

class ComposeView: UIViewController {
    
    var pickerHeight : CGFloat = 0.0
    
    var toContactPicker: ContactPicker!
    var toContacts: String {
        return toContactPicker.contactList
    }
    
    var hasOutSideEmails : Bool {
        let toHas = toContactPicker.hasOutsideEmails
        if (toHas) {
            return true;
        }
        
        let ccHas = ccContactPicker.hasOutsideEmails
        if (ccHas) {
            return true;
        }
        
        let bccHas = bccContactPicker.hasOutsideEmails
        if (bccHas) {
            return true;
        }
        
        return false
    }
    
    var hasNonePMEmails : Bool {
        let toHas = toContactPicker.hasNonePM
        if (toHas) {
            return true;
        }
        
        let ccHas = ccContactPicker.hasNonePM
        if (ccHas) {
            return true;
        }
        
        let bccHas = bccContactPicker.hasNonePM
        if (bccHas) {
            return true;
        }
        
        return false
    }
 

    var hasPGPPinned : Bool {
        let toHas = toContactPicker.hasPGPPinned
        if (toHas) {
            return true;
        }
        
        let ccHas = ccContactPicker.hasPGPPinned
        if (ccHas) {
            return true;
        }
        
        let bccHas = bccContactPicker.hasPGPPinned
        if (bccHas) {
            return true;
        }
        
        return false
    }
    
    var nonePMEmails : [String] {
        var out : [String] = [String]()
        out.append(contentsOf: toContactPicker.nonePMEmails)
        out.append(contentsOf: ccContactPicker.nonePMEmails)
        out.append(contentsOf: bccContactPicker.nonePMEmails)
        return out
    }
    
    var pgpEmails : [String] {
        var out : [String] = [String]()
        out.append(contentsOf: toContactPicker.pgpEmails)
        out.append(contentsOf: ccContactPicker.pgpEmails)
        out.append(contentsOf: bccContactPicker.pgpEmails)
        return out
    }
    
    var allEmails : String {  // email,email,email
        var emails : [String] = []
        
        let toEmails = toContactPicker.contactList
        if !toEmails.isEmpty  {
            emails.append(toEmails)
        }
        
        let ccEmails = ccContactPicker.contactList
        if !ccEmails.isEmpty  {
            emails.append(ccEmails)
        }
        
        let bccEmails = bccContactPicker.contactList
        if !bccEmails.isEmpty  {
            emails.append(bccEmails)
        }
        if emails.isEmpty {
            return ""
        }
        return emails.joined(separator: ",")
    }
    
    
    
    var ccContactPicker: ContactPicker!
    var ccContacts: String {
        return ccContactPicker.contactList
    }
    var bccContactPicker: ContactPicker!
    var bccContacts: String {
        return bccContactPicker.contactList
    }
    
    var expirationTimeInterval: TimeInterval = 0
    
    var hasContent: Bool {//need check body also here
        return !toContacts.isEmpty || !ccContacts.isEmpty || !bccContacts.isEmpty || !subjectTitle.isEmpty
    }
    
    var subjectTitle: String {
        return subject.text ?? ""
    }
    
    // MARK : - Outlets
    @IBOutlet var fakeContactPickerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var subject: UITextField!
    @IBOutlet var showCcBccButton: UIButton!
    
    // MARK: - Action Buttons
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet var encryptedButton: UIButton!
    @IBOutlet var expirationButton: UIButton!
    @IBOutlet var attachmentButton: UIButton!
    fileprivate var confirmExpirationButton: UIButton!
    
    // MARK: - Encryption password
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet var encryptedPasswordTextField: UITextField!
    @IBOutlet var encryptedActionButton: UIButton!
    
    
    // MARK: - Expiration Date
    @IBOutlet var expirationView: UIView!
    @IBOutlet var expirationDateTextField: UITextField!
    
    // MARK: - From field
    @IBOutlet weak var fromView: UIView!
    @IBOutlet weak var fromAddress: UILabel!
    @IBOutlet weak var fromPickerButton: UIButton!
    @IBOutlet weak var fromLable: UILabel!
    
    // MARK: - Delegate and Datasource
    weak var datasource: ComposeViewDataSource?
    weak var delegate: ComposeViewDelegate?
    
    var selfView : UIView!
    
    // MARK: - Constants
    fileprivate let kDefaultRecipientHeight : Int = 44
    fileprivate let kErrorMessageHeight: CGFloat = 48.0
    fileprivate let kNumberOfColumnsInTimePicker: Int = 2
    fileprivate let kNumberOfDaysInTimePicker: Int = 30
    fileprivate let kNumberOfHoursInTimePicker: Int = 24
    fileprivate let kCcBccContainerViewHeight: CGFloat = 96.0
    
    //
    fileprivate let kAnimationDuration = 0.25
    
    //
    fileprivate var errorView: ComposeErrorView!
    fileprivate var isShowingCcBccView: Bool = false
    fileprivate var hasExpirationSchedule: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.selfView = self.view;
        
        fromLable.text = LocalString._composer_from_label
        subject.placeholder = LocalString._composer_subject_placeholder
        encryptedPasswordTextField.placeholder = LocalString._composer_define_expiration_placeholder
        
        self.configureContactPickerTemplate()
        self.includeButtonBorder(encryptedButton)
        self.includeButtonBorder(expirationButton)
        self.includeButtonBorder(attachmentButton)
        self.includeButtonBorder(encryptedPasswordTextField)
        self.includeButtonBorder(expirationDateTextField)
        
        self.configureToContactPicker()
        self.configureCcContactPicker()
        self.configureBccContactPicker()
        self.configureSubject()
        
        self.configureEncryptionPasswordField()
        self.configureExpirationField()
        self.configureErrorMessage()
        
        self.view.bringSubviewToFront(showCcBccButton)
        self.view.bringSubviewToFront(subject);
        self.view.sendSubviewToBack(ccContactPicker)
        self.view.sendSubviewToBack(bccContactPicker)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.notifyViewSize( false )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func reloadPicker() {
        self.toContactPicker.reload()
        self.ccContactPicker.reload()
        self.bccContactPicker.reload()
    }
    
    @IBAction func contactPlusButtonTapped(_ sender: UIButton) {
        self.plusButtonHandle();
        self.notifyViewSize(true)
    }
    
    @IBAction func fromPickerAction(_ sender: AnyObject) {
        self.delegate?.composeViewPickFrom(self)
    }
    
    func updateFromValue (_ email: String , pickerEnabled : Bool) {
        fromAddress.text = email
        fromPickerButton.isEnabled = pickerEnabled
    }
    
    @IBAction func attachmentButtonTapped(_ sender: UIButton) {
        self.hidePasswordAndConfirmDoesntMatch()
        self.view.endEditing(true)
        self.delegate?.composeViewDidTapAttachmentButton(self)
    }
    
    func updateAttachmentButton(_ hasAtts: Bool) {
        if hasAtts {
            self.attachmentButton.setImage(UIImage(named: "compose_attachment-active"), for: UIControl.State())
        } else {
            self.attachmentButton.setImage(UIImage(named: "compose_attachment"), for: UIControl.State())
        }
    }
    
    @IBAction func expirationButtonTapped(_ sender: UIButton) {
        self.hidePasswordAndConfirmDoesntMatch()
        self.view.endEditing(true)
        let _ = self.toContactPicker.becomeFirstResponder()
        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
            self.passwordView.alpha = 0.0
            self.buttonView.alpha = 0.0
            self.expirationView.alpha = 1.0
            
            self.toContactPicker.isUserInteractionEnabled = false
            self.ccContactPicker.isUserInteractionEnabled = false
            self.bccContactPicker.isUserInteractionEnabled = false
            self.subject.isUserInteractionEnabled = false
            
            self.showExpirationPicker()
            let _ = self.toContactPicker.resignFirstResponder()
        })
    }
    
    @IBAction func encryptedButtonTapped(_ sender: UIButton) {
        self.hidePasswordAndConfirmDoesntMatch()
        self.delegate?.composeViewDidTapEncryptedButton(self)
    }
    
    @IBAction func didTapExpirationDismissButton(_ sender: UIButton) {
        self.hideExpirationPicker()
    }
    
    @IBAction func didTapEncryptedDismissButton(_ sender: UIButton) {
        self.delegate?.composeViewDidTapEncryptedButton(self)
        self.encryptedPasswordTextField.resignFirstResponder()
        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
            self.encryptedPasswordTextField.text = ""
            self.passwordView.alpha = 0.0
            self.buttonView.alpha = 1.0
        })
    }
    
    
    // Mark: -- Private Methods
    fileprivate func includeButtonBorder(_ view: UIView) {
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.ProtonMail.Gray_C9CED4.cgColor
    }
    
    fileprivate func configureEncryptionPasswordField() {
        let passwordLeftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: self.encryptedPasswordTextField.frame.size.height))
        encryptedPasswordTextField.leftView = passwordLeftPaddingView
        encryptedPasswordTextField.leftViewMode = UITextField.ViewMode.always
        
        let nextButton = UIButton()
        nextButton.addTarget(self, action: #selector(ComposeView.didTapNextButton), for: UIControl.Event.touchUpInside)
        nextButton.setImage(UIImage(named: "next"), for: UIControl.State())
        nextButton.sizeToFit()
        
        let nextView = UIView(frame: CGRect(x: 0, y: 0, width: nextButton.frame.size.width + 10, height: nextButton.frame.size.height))
        nextView.addSubview(nextButton)
        encryptedPasswordTextField.rightView = nextView
        encryptedPasswordTextField.rightViewMode = UITextField.ViewMode.always
    }
    
    fileprivate func configureExpirationField() {
        let expirationLeftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: self.expirationDateTextField.frame.size.height))
        expirationDateTextField.leftView = expirationLeftPaddingView
        expirationDateTextField.leftViewMode = UITextField.ViewMode.always
        
        self.confirmExpirationButton = UIButton()
        confirmExpirationButton.addTarget(self, action: #selector(ComposeView.didTapConfirmExpirationButton), for: UIControl.Event.touchUpInside)
        confirmExpirationButton.setImage(UIImage(named: "next"), for: UIControl.State())
        confirmExpirationButton.sizeToFit()
        
        let confirmView = UIView(frame: CGRect(x: 0, y: 0, width: confirmExpirationButton.frame.size.width + 10, height: confirmExpirationButton.frame.size.height))
        confirmView.addSubview(confirmExpirationButton)
        expirationDateTextField.rightView = confirmView
        expirationDateTextField.rightViewMode = UITextField.ViewMode.always
        expirationDateTextField.delegate = self
    }
    
    fileprivate func configureErrorMessage() {
        self.errorView = ComposeErrorView()
        self.errorView.backgroundColor = UIColor.white
        self.errorView.clipsToBounds = true
        self.errorView.backgroundColor = UIColor.darkGray
        self.view.addSubview(errorView)
    }
    
    fileprivate func configureContactPickerTemplate() {
        ContactCollectionViewContactCell.appearance().tintColor = UIColor.ProtonMail.Blue_6789AB
        ContactCollectionViewContactCell.appearance().font = Fonts.h6.light
        ContactCollectionViewPromptCell.appearance().font = Fonts.h6.light
        ContactCollectionViewEntryCell.appearance().font = Fonts.h6.light
    }
    
    ///
    internal func notifyViewSize(_ animation : Bool) {
        UIView.animate(withDuration: animation ? self.kAnimationDuration : 0, delay:0, options: UIView.AnimationOptions(), animations: {
            self.updateViewSize()
            let size = CGSize(width: self.view.frame.width, height: self.passwordView.frame.origin.y + self.passwordView.frame.height + self.pickerHeight)
            self.delegate?.ComposeViewDidSizeChanged(size, showPicker: self.pickerHeight > 0.0)
            }, completion: nil)
    }
    
    internal func configureSubject() {
        let subjectLeftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: self.subject.frame.size.height))
        self.subject.leftView = subjectLeftPaddingView
        self.subject.leftViewMode = UITextField.ViewMode.always
        self.subject.autocapitalizationType = .sentences
        
    }
    
    internal func plusButtonHandle() {
        if (isShowingCcBccView) {
            UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
                self.fakeContactPickerHeightConstraint.constant = self.toContactPicker.currentContentHeight
                self.ccContactPicker.alpha = 0.0
                self.bccContactPicker.alpha = 0.0
                self.showCcBccButton.setImage(UIImage(named: "compose_pluscontact"), for:UIControl.State() )
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
                self.ccContactPicker.alpha = 1.0
                self.bccContactPicker.alpha = 1.0
                self.fakeContactPickerHeightConstraint.constant = self.toContactPicker.currentContentHeight + self.ccContactPicker.currentContentHeight + self.bccContactPicker.currentContentHeight
                self.showCcBccButton.setImage(UIImage(named: "compose_minuscontact"), for:UIControl.State() )
                self.view.layoutIfNeeded()
            })
        }
        
        isShowingCcBccView = !isShowingCcBccView
    }
    
    @objc internal func didTapConfirmExpirationButton() {
        self.delegate?.composeViewCollectExpirationData(self)
    }
    
    @objc internal func didTapNextButton() {
        self.delegate?.composeViewDidTapNextButton(self)
    }
    
    
    internal func showConfirmPasswordView() {
        self.encryptedPasswordTextField.placeholder = LocalString._composer_eo_confirm_pwd_placeholder
        self.encryptedPasswordTextField.isSecureTextEntry = true
        self.encryptedPasswordTextField.text = ""
    }
    
    internal func showPasswordHintView() {
        self.encryptedPasswordTextField.placeholder = LocalString._define_hint_optional
        self.encryptedPasswordTextField.isSecureTextEntry = false
        self.encryptedPasswordTextField.text = ""
    }
    
    internal func showEncryptionDone() {
        didTapEncryptedDismissButton(encryptedButton)
        self.encryptedPasswordTextField.placeholder = LocalString._composer_define_password
        self.encryptedPasswordTextField.isSecureTextEntry = true
        self.encryptedButton.setImage(UIImage(named: "compose_lock-active"), for: UIControl.State())
    }
    
    internal func showEncryptionRemoved() {
        didTapEncryptedDismissButton(encryptedButton)
        self.encryptedButton.setImage(UIImage(named: "compose_lock"), for: UIControl.State())
    }
    
    internal func showExpirationPicker() {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.delegate?.composeViewDidTapExpirationButton(self)
        })
    }
    
    internal func hideExpirationPicker() {
        self.toContactPicker.isUserInteractionEnabled = true
        self.ccContactPicker.isUserInteractionEnabled = true
        self.bccContactPicker.isUserInteractionEnabled = true
        self.subject.isUserInteractionEnabled = true
        //self.htmlEditor.view.userInteractionEnabled = true
        
        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
            self.expirationView.alpha = 0.0
            self.buttonView.alpha = 1.0
            self.delegate?.composeViewHideExpirationView(self)
        })
    }
    
    internal func showPasswordAndConfirmDoesntMatch(_ error : String) {
        self.errorView.backgroundColor = UIColor.ProtonMail.Red_FF5959
        
        self.errorView.mas_updateConstraints { (update) -> Void in
            update?.removeExisting = true
            let _ = update?.left.equalTo()(self.selfView)
            let _ = update?.right.equalTo()(self.selfView)
            let _ = update?.height.equalTo()(self.kErrorMessageHeight)
            let _ = update?.top.equalTo()(self.encryptedPasswordTextField.mas_bottom)
        }
        
        self.errorView.setError(error, withShake: true)
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            
        })
    }
    
    internal func hidePasswordAndConfirmDoesntMatch() {
        self.errorView.mas_updateConstraints { (update) -> Void in
            update?.removeExisting = true
            let _ = update?.left.equalTo()(self.view)
            let _ = update?.right.equalTo()(self.view)
            let _ = update?.height.equalTo()(0)
            let _ = update?.top.equalTo()(self.encryptedPasswordTextField.mas_bottom)
        }
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            //self.layoutIfNeeded()
        })
    }
    
    func updateExpirationValue(_ intagerV : TimeInterval, text : String) {
        self.expirationDateTextField.text = text
        self.expirationTimeInterval = intagerV
    }
    
    func setExpirationValue (_ day : Int, hour : Int) -> Bool {
        if (day == 0 && hour == 0 && !hasExpirationSchedule) {
            self.expirationDateTextField.shake(3, offset: 10.0)
            
            return false
            
        } else {
            if (!hasExpirationSchedule) {
                self.expirationButton.setImage(UIImage(named: "compose_expiration-active"), for: UIControl.State())
                self.confirmExpirationButton.setImage(UIImage(named: "compose_expiration_cancel"), for: UIControl.State())
            } else {
                self.expirationDateTextField.text = ""
                self.expirationTimeInterval  = 0;
                self.expirationButton.setImage(UIImage(named: "compose_expiration"), for: UIControl.State())
                self.confirmExpirationButton.setImage(UIImage(named: "next"), for: UIControl.State())
                self.delegate?.composeViewCancelExpirationData(self)
                
            }
            hasExpirationSchedule = !hasExpirationSchedule
            self.hideExpirationPicker()
            return true
        }
    }
    
    fileprivate func updateViewSize() {
        //let size = CGSize(width: self.view.frame.width, height: self.passwordView.frame.origin.y + self.passwordView.frame.height)
        //self.htmlEditor.view.frame = CGRect(x: 0, y: size.height, width: editorSize.width, height: editorSize.height)
        //self.htmlEditor.setFrame(CGRect(x: 0, y: 0, width: editorSize.width, height: editorSize.height))
    }
    
    fileprivate func configureToContactPicker() {
        toContactPicker = ContactPicker()
        toContactPicker.translatesAutoresizingMaskIntoConstraints = true
        toContactPicker.cellHeight = self.kDefaultRecipientHeight;
        self.view.addSubview(toContactPicker)
        toContactPicker.datasource = self
        toContactPicker.delegate = self
        
        toContactPicker.mas_makeConstraints { (make) -> Void in
            let _ = make?.top.equalTo()(self.fromView.mas_bottom)?.with().offset()(5)
            let _ = make?.left.equalTo()(self.selfView)
            let _ = make?.right.equalTo()(self.selfView)
            let _ = make?.height.equalTo()(self.kDefaultRecipientHeight)
        }
    }
    
    fileprivate func configureCcContactPicker() {
        ccContactPicker = ContactPicker()
        self.view.addSubview(ccContactPicker)
        
        ccContactPicker.datasource = self
        ccContactPicker.delegate = self
        ccContactPicker.alpha = 0.0
        
        ccContactPicker.mas_makeConstraints { (make) -> Void in
            let _ = make?.top.equalTo()(self.toContactPicker.mas_bottom)
            let _ = make?.left.equalTo()(self.selfView)
            let _ = make?.right.equalTo()(self.selfView)
            let _ = make?.height.equalTo()(self.toContactPicker)
        }
    }
    
    fileprivate func configureBccContactPicker() {
        bccContactPicker = ContactPicker()
        self.view.addSubview(bccContactPicker)
        
        bccContactPicker.datasource = self
        bccContactPicker.delegate = self
        bccContactPicker.alpha = 0.0
        
        bccContactPicker.mas_makeConstraints { (make) -> Void in
            let _ = make?.top.equalTo()(self.ccContactPicker.mas_bottom)
            let _ = make?.left.equalTo()(self.selfView)
            let _ = make?.right.equalTo()(self.selfView)
            let _ = make?.height.equalTo()(self.ccContactPicker)
        }
    }
    
    fileprivate func updateContactPickerHeight(_ contactPicker: ContactPicker, newHeight: CGFloat) {
        if (contactPicker == self.toContactPicker) {
            toContactPicker.mas_updateConstraints({ (make) -> Void in
                make?.removeExisting = true
                let _ = make?.top.equalTo()(self.fromView.mas_bottom)
                let _ = make?.left.equalTo()(self.selfView)
                let _ = make?.right.equalTo()(self.selfView)
                let _ = make?.height.equalTo()(newHeight)
            })
        }
        else if (contactPicker == self.ccContactPicker) {
            ccContactPicker.mas_updateConstraints({ (make) -> Void in
                make?.removeExisting = true
                let _ = make?.top.equalTo()(self.toContactPicker.mas_bottom)
                let _ = make?.left.equalTo()(self.selfView)
                let _ = make?.right.equalTo()(self.selfView)
                let _ = make?.height.equalTo()(newHeight)
            })
        } else if (contactPicker == self.bccContactPicker) {
            bccContactPicker.mas_updateConstraints({ (make) -> Void in
                make?.removeExisting = true
                let _ = make?.top.equalTo()(self.ccContactPicker.mas_bottom)
                let _ = make?.left.equalTo()(self.selfView)
                let _ = make?.right.equalTo()(self.selfView)
                let _ = make?.height.equalTo()(newHeight)
            })
        }
        
        if (isShowingCcBccView) {
            fakeContactPickerHeightConstraint.constant = toContactPicker.currentContentHeight + ccContactPicker.currentContentHeight + bccContactPicker.currentContentHeight
        } else {
            fakeContactPickerHeightConstraint.constant = toContactPicker.currentContentHeight
        }
        contactPicker.contactCollectionView?.add(border: .bottom,
                                                 color: UIColor.ProtonMail.Gray_C9CED4,
                                                 borderWidth: 1.0,
                                                 at: newHeight)
    }
}


// MARK: - ContactPickerDataSource
extension ComposeView: ContactPickerDataSource {
    
    func picker(contactPicker: ContactPicker, model: ContactPickerModelProtocol, progress: () -> Void, complete: ((UIImage?, Int) -> Void)?) {
        self.delegate?.lockerCheck(model: model, progress: progress, complete: complete)
    }
    
    
    func contactModelsForContactPicker(contactPickerView: ContactPicker) -> [ContactPickerModelProtocol] {
        if (contactPickerView == toContactPicker) {
            contactPickerView.prompt = LocalString._composer_to_label
        } else if (contactPickerView == ccContactPicker) {
            contactPickerView.prompt = LocalString._composer_cc_label
        } else if (contactPickerView == bccContactPicker) {
            contactPickerView.prompt = LocalString._composer_bcc_label
        }
        return self.datasource?.composeViewContactsModelForPicker(self, picker: contactPickerView) ?? [ContactPickerModelProtocol]()
    }
    
    func selectedContactModelsForContactPicker(contactPickerView: ContactPicker) -> [ContactPickerModelProtocol] {
        return self.datasource?.composeViewSelectedContactsForPicker(self, picker: contactPickerView) ?? [ContactPickerModelProtocol]()
    }
}


// MARK: - ContactPickerDelegate
extension ComposeView: ContactPickerDelegate {
    func contactPicker(contactPicker: ContactPicker, didUpdateContentHeightTo newHeight: CGFloat) {
        self.updateContactPickerHeight(contactPicker, newHeight: newHeight)
    }
    
    func didShowFilteredContactsForContactPicker(contactPicker: ContactPicker) { 
        self.delegate?.composeViewWillPresentSubview()
    }
    
    func didHideFilteredContactsForContactPicker(contactPicker: ContactPicker) {
        self.delegate?.composeViewWillDismissSubview()
        self.view.sendSubviewToBack(contactPicker)
        if (contactPicker.frame.size.height > contactPicker.currentContentHeight) {
            self.updateContactPickerHeight(contactPicker, newHeight: contactPicker.currentContentHeight)
        }
        self.pickerHeight = 0;
        self.notifyViewSize(false)
    }
    
    func contactPicker(contactPicker: ContactPicker, didEnterCustomText text: String, needFocus focus: Bool) {
        let customContact = ContactVO(id: "", name: text, email: text)
        contactPicker.addToSelectedContacts(model: customContact, needFocus: focus)
    }
    
    func contactPicker(picker: ContactPicker, pasted text: String, needFocus focus: Bool) {
        if text.contains(check: ",") {
            let cusTexts = text.split(separator: ",")
            for cusText in cusTexts {
                let trimmed = cusText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    let customContact = ContactVO(id: "", name: trimmed, email: trimmed)
                    picker.addToSelectedContacts(model: customContact, needFocus: focus)
                }
            }
        } else if text.contains(check: ";") {
            let cusTexts = text.split(separator: ";")
            for cusText in cusTexts {
                let trimmed = cusText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    let customContact = ContactVO(id: "", name: trimmed, email: trimmed)
                    picker.addToSelectedContacts(model: customContact, needFocus: focus)
                }
            }
        } else {
            let customContact = ContactVO(id: "", name: text, email: text)
            picker.addToSelectedContacts(model: customContact, needFocus: focus)
        }
    }
    
    func useCustomFilter() -> Bool {
        return true
    }
    
    func customFilterPredicate(searchString: String) -> NSPredicate {
        return NSPredicate(format: "contactTitle CONTAINS[cd] %@ or contactSubtitle CONTAINS[cd] %@", argumentArray: [searchString, searchString])
    }
    
    func collectionView(at: UICollectionView?, willChangeContentSizeTo newSize: CGSize) {
        
    }
    
    func collectionView(at: ContactCollectionView, entryTextDidChange text: String) {
        
    }
    
    func collectionView(at: ContactCollectionView, didEnterCustom text: String, needFocus focus: Bool) {
        
    }
    
    func collectionView(at: ContactCollectionView, didSelect contact: ContactPickerModelProtocol) {
        
    }
    
    func collectionView(at: ContactCollectionView, didAdd contact: ContactPickerModelProtocol) {
        let contactPicker = contactPickerForContactCollectionView(at)
        self.notifyViewSize(true)
        self.delegate?.composeView(self, didAddContact: contact, toPicker: contactPicker)
    }
    
    func collectionView(at: ContactCollectionView, didRemove contact: ContactPickerModelProtocol) {
        let contactPicker = contactPickerForContactCollectionView(at)
        self.notifyViewSize(true)
        self.delegate?.composeView(self, didRemoveContact: contact, fromPicker: contactPicker)
    }
    
    func collectionView(at: ContactCollectionView, pasted text: String, needFocus focus: Bool) {
        
    }
    
    func collectionContactCell(lockCheck model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?) {
        self.delegate?.lockerCheck(model: model, progress: progress, complete: complete)
    }
    
    // MARK: Private delegate helper methods
    fileprivate func contactPickerForContactCollectionView(_ contactCollectionView: ContactCollectionView) -> ContactPicker {
        var contactPicker: ContactPicker = toContactPicker
        if (contactCollectionView == toContactPicker.contactCollectionView) {
            contactPicker = toContactPicker
        } else if (contactCollectionView == ccContactPicker.contactCollectionView) {
            contactPicker = ccContactPicker
        } else if (contactCollectionView == bccContactPicker.contactCollectionView) {
            contactPicker = bccContactPicker
        }
        return contactPicker
    }
}


// MARK: - UITextFieldDelegate
extension ComposeView: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if (textField == expirationDateTextField) {
            return false
        }
        return true
    }
}

// MARK: - ContactPicker extension
extension ContactPicker {
    // TODO: contact group email expansion
    var contactList: String {
        var contactList = ""
        let contactsSelected = NSArray(array: self.contactsSelected)
        if let contacts = contactsSelected.value(forKey: ContactVO.Attributes.email) as? [String] {
            contactList = contacts.joined(separator: ",")
        }
        return contactList
    }

    //TODO:: the hard code at here should be moved to enum / struture
    var hasOutsideEmails: Bool {
        let contactsSelected = NSArray(array: self.contactsSelected)
        if let contacts = contactsSelected.value(forKey: ContactVO.Attributes.email) as? [String] {
            for contact in contacts {
                if contact.lowercased().range(of: "@protonmail.ch") == nil && contact.lowercased().range(of: "@protonmail.com") == nil && contact.lowercased().range(of: "@pm.me") == nil {
                    return true
                }
            }
        }
        return false
    }
    
    var hasPGPPinned : Bool {
        for contact in self.contactsSelected {
            if contact.hasPGPPined {
                return true
            }
        }
        return false
    }
    
    var hasNonePM : Bool {
        for contact in self.contactsSelected {
            if contact.hasNonePM {
                return true
            }
        }
        return false
    }
    
    var pgpEmails : [String] {
        var out : [String] = [String]()
        for contact in self.contactsSelected {
            if contact.hasPGPPined, let email = contact.displayEmail {
                out.append(email)
            }
        }
        return out
    }
    
    var nonePMEmails : [String] {
        var out : [String] = [String]()
        for contact in self.contactsSelected {
            if contact.hasNonePM , let email = contact.displayEmail {
                out.append(email)
            }
        }
        return out
    }
}

