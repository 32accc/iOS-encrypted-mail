//
//  ComposerRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

/// Composer identifiers.
fileprivate let sendButtonIdentifier = "ComposeContainerViewController.sendButton"
fileprivate let toTextFieldIdentifier = "ToTextField"
fileprivate let ccTextFieldIdentifier = "ccTextField"
fileprivate let bccTextFieldIdentifier = "bccTextField"
fileprivate let subjectTextFieldIdentifier = "ComposeHeaderViewController.subject"
fileprivate let pasteMenuItem = app.menuItems.staticTexts.element(boundBy: 0)
fileprivate let popoverDismissRegionOtherIdentifier = "PopoverDismissRegion"
fileprivate let expirationButtonIdentifier = "ComposeHeaderViewController.expirationButton"
fileprivate let passwordButtonIdentifier = "ComposeHeaderViewController.encryptedButton"
fileprivate let attachmentButtonIdentifier = "ComposeHeaderViewController.attachmentButton"
fileprivate let showCcBccButtonIdentifier = "ComposeHeaderViewController.showCcBccButton"

/// Set Password modal identifiers.
fileprivate let messagePasswordSecureTextFieldIdentifier = "ComposePasswordViewController.passwordField"
fileprivate let confirmPasswordSecureTextFieldIdentifier = "ComposePasswordViewController.confirmPasswordField"
fileprivate let hintPasswordTextFieldIdentifier = "ComposePasswordViewController.hintField"
fileprivate let cancelButtonIdentifier = "ComposePasswordViewController.cancelButton"
fileprivate let applyButtonIdentifier = "ComposePasswordViewController.applyButton"

/// Expiration picker identifiers.
fileprivate let expirationPickerIdentifier = "ExpirationPickerCell.picker"
fileprivate let expirationActionButtonIdentifier = "expirationActionButton"

//expirationDateTextField

/**
 Represents Composer view.
*/
class ComposerRobot {
    
    var verify: Verify! = nil
    init() { verify = Verify(parent: self) }
    
    func sendMessage(_ to: String, _ subjectText: String) -> InboxRobot {
        return recipients(to)
            .subject(subjectText)
            .send()
    }
    
    func sendMessageToContact(_ subjectText: String) -> ContactDetailsRobot {
        return subject(subjectText)
            .sendToContact()
    }
    
    func sendMessageToGroup(_ subjectText: String) -> ContactsRobot {
        return subject(subjectText)
            .sendToContactGroup()
    }
    
    func sendMessage(_ to: String, _ cc: String, _ subjectText: String) -> InboxRobot {
        return recipients(to)
            .cc(cc)
            .subject(subjectText)
            .send()
    }
    
    func sendMessage(_ to: String, _ cc: String, _ bcc: String, _ subjectText: String) -> InboxRobot {
        return recipients(to)
            .showCcBcc()
            .cc(cc)
            .bcc(bcc)
            .subject(subjectText)
            .send()
    }
    
    func sendMessageWithPassword(_ to: String, _ subjectText: String, _ body: String, _ password: String, _ hint: String) -> InboxRobot {
        return composeMessage(to, subjectText, body)
            .setMessagePassword()
            .definePasswordWithHint(password, hint)
            .send()
    }
    
    func sendMessageExpiryTimeInDays(_ to: String, _ subjectText: String, _ body: String, expireInDays: Int = 1) -> InboxRobot {
        recipients(to)
            .subject(subjectText)
            .messageExpiration()
            .setExpirationInDays(expireInDays)
            .send()
        return InboxRobot()
    }
    
    func sendMessageEOAndExpiryTime(_ to: String, _ subjectText: String, _ password: String, _ hint: String, expireInDays: Int = 1) -> InboxRobot {
        recipients(to)
            .subject(subjectText)
            .setMessagePassword()
            .definePasswordWithHint(password, hint)
            .messageExpiration()
            .setExpirationInDays(expireInDays)
            .send()
        return InboxRobot()
    }
    
    func sendMessageWithAttachments(_ to: String, _ subjectText: String, attachmentsAmount: Int = 1) -> InboxRobot {
        recipients(to)
            .subject(subjectText)
            .addAttachment()
            .add()
            .photoLibrary()
            .pickImages(attachmentsAmount)
            .done()
            .send()
        return InboxRobot()
    }
    
    func sendMessageEOAndExpiryTimeWithAttachment(_ to: String, _ subjectText: String, _ password: String, _ hint: String, attachmentsAmount: Int = 1, expireInDays: Int = 1) -> InboxRobot {
        recipients(to)
            .subject(subjectText)
            .addAttachment()
            .add()
            .photoLibrary()
            .pickImages(attachmentsAmount)
            .done()
            .setMessagePassword()
            .definePasswordWithHint(password, hint)
            .messageExpiration()
            .setExpirationInDays(expireInDays)
            .send()
        return InboxRobot()
    }
    
    @discardableResult
    private func send() -> InboxRobot {
        Element.wait.forHittableButton(sendButtonIdentifier, file: #file, line: #line).tap()
        return InboxRobot()
    }
    
    private func sendToContact() -> ContactDetailsRobot {
        Element.wait.forHittableButton(sendButtonIdentifier, file: #file, line: #line).tap()
        return ContactDetailsRobot()
    }
    
    private func sendToContactGroup() -> ContactsRobot {
        Element.wait.forHittableButton(sendButtonIdentifier, file: #file, line: #line).tap()
        return ContactsRobot()
    }
    
    private func recipients(_ email: String) -> ComposerRobot {
        Element.wait.forTextFieldWithIdentifier(toTextFieldIdentifier, file: #file, line: #line).tap()
        Element.textField.tapByIdentifier(toTextFieldIdentifier).typeText(email)
        Element.other.tapIfExists(popoverDismissRegionOtherIdentifier)
        return self
    }
    
    private func cc(_ email: String) -> ComposerRobot {
        Element.wait.forTextFieldWithIdentifier(ccTextFieldIdentifier, file: #file, line: #line).tap()
        Element.textField.tapByIdentifier(ccTextFieldIdentifier).typeText(email)
        Element.other.tapIfExists(popoverDismissRegionOtherIdentifier)
        return self
    }
    
    private func bcc(_ email: String) -> ComposerRobot {
        Element.wait.forTextFieldWithIdentifier(bccTextFieldIdentifier, file: #file, line: #line).tap()
        Element.textField.tapByIdentifier(bccTextFieldIdentifier).typeText(email)
        Element.other.tapIfExists(popoverDismissRegionOtherIdentifier)
        return self
    }
    
    private  func subject(_ subjectText: String) -> ComposerRobot {
        Element.wait.forTextFieldWithIdentifier(subjectTextFieldIdentifier, file: #file, line: #line).tap()
        Element.textField(subjectTextFieldIdentifier).perform.typeText(subjectText)
        return self
    }
    
    private func body(_ text: String) -> ComposerRobot {
        
        return self
    }
    
    func pasteSubject(_ subjectText: String) -> ComposerRobot {
        Element.system.saveToClipBoard(subjectText)
        Element.wait.forTextFieldWithIdentifier(subjectTextFieldIdentifier, file: #file, line: #line).tap()
        Element.wait.forTextFieldWithIdentifier(subjectTextFieldIdentifier, file: #file, line: #line).press(forDuration: 3)
        pasteMenuItem.tap()
        return self
    }
    
    private func composeMessage(_ to: String, _ subject: String, _ body: String) -> ComposerRobot {
        return recipients(to)
            .subject(subject)
            .body(body)
    }
    
    private func setMessagePassword() -> MessagePasswordRobot  {
        Element.button.tapByIdentifier(passwordButtonIdentifier)
        return MessagePasswordRobot()
    }
    
    private func addAttachment() -> MessageAttachmentsRobot  {
        Element.button.tapByIdentifier(attachmentButtonIdentifier)
        return MessageAttachmentsRobot()
    }
    
    private func showCcBcc() -> ComposerRobot {
        Element.button.tapByIdentifier(showCcBccButtonIdentifier)
        return self
    }
    
    private func messageExpiration() -> MessageExpirationRobot {
        Element.button.tapByIdentifier(expirationButtonIdentifier)
        return MessageExpirationRobot()
    }
    
    /**
     Class represents Message Password dialog.
     */
    class MessagePasswordRobot {
        func definePasswordWithHint(_ password: String, _ hint: String) -> ComposerRobot {
            return definePassword(password)
                .confirmPassword(password)
                .defineHint(hint)
                .applyPassword()
        }

        private func definePassword(_ password: String) -> MessagePasswordRobot {
            Element.secureTextField.tapByIdentifier(messagePasswordSecureTextFieldIdentifier).typeText(password)
            return self
        }

        private func confirmPassword(_ password: String) -> MessagePasswordRobot {
            Element.secureTextField.tapByIdentifier(confirmPasswordSecureTextFieldIdentifier).typeText(password)
            return self
        }

        private func defineHint(_ hint: String) -> MessagePasswordRobot {
            Element.textField.tapByIdentifier(hintPasswordTextFieldIdentifier).typeText(hint)
            return self
        }

        private func applyPassword() -> ComposerRobot {
            Element.button.tapByIdentifier(applyButtonIdentifier)
            return ComposerRobot()
        }
    }
    
    /**
     Class represents Message Expiration dialog.
     */
    class MessageExpirationRobot {
        @discardableResult
        func setExpirationInDays(_ days: Int) -> ComposerRobot {
            return expirationDays(days)
                .confirmMessageExpiration()
        }

        private func expirationDays(_ days: Int) -> MessageExpirationRobot {
            Element.pickerWheel.setPickerWheelValue(pickerWheelIndex: 0, value: days, dimension: "Days")
            return self
        }
        
        private func expirationHours(_ hours: Int) -> MessageExpirationRobot {
            Element.pickerWheel.setPickerWheelValue(pickerWheelIndex: 1, value: hours, dimension: "Hours")
            return self
        }

        private func confirmMessageExpiration() -> ComposerRobot {
            //Element.button.tapByIdentifier(expirationActionButtonIdentifier)
            return ComposerRobot()
        }
    }
    
    /**
     Contains all the validations that can be performed by ComposerRobot.
    */
    class Verify {
        unowned let composerRobot: ComposerRobot
        init(parent: ComposerRobot) { composerRobot = parent }
    }
}
