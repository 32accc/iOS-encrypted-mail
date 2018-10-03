//
//  TwoFACodeViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/3/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation
import UIKit

protocol TwoFACodeViewControllerDelegate {
    func Cancel2FA()
    func ConfirmedCode(_ code : String, pwd:String)
}

class TwoFACodeViewController : UIViewController {
    //var viewModel : TwoFAViewModel!
    @IBOutlet weak var twoFACodeView: TwoFACodeView!
    var delegate : TwoFACodeViewControllerDelegate?
    
    var mode : AuthMode!
    
    @IBOutlet weak var tfaCodeCenterConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        self.twoFACodeView.delegate = self
        self.twoFACodeView.layer.cornerRadius = 8;
        self.twoFACodeView.initViewMode(mode)
        self.twoFACodeView.showKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addKeyboardObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension TwoFACodeViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        tfaCodeCenterConstraint.constant = 0.0
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        if let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            tfaCodeCenterConstraint.constant = (keyboardSize.height / 2) * -1.0
        }
    }
}


extension TwoFACodeViewController : TwoFACodeViewDelegate {

    func ConfirmedCode(_ code: String, pwd : String) {
        delegate?.ConfirmedCode(code, pwd:pwd)
        self.dismiss(animated: true, completion: nil)
    }
    
    func Cancel() {
        delegate?.Cancel2FA()
        self.dismiss(animated: true, completion: nil)
    }
}
