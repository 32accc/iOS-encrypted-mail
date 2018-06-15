//
//  ContactCollectionViewEntryCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/27/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit


@objc protocol UITextFieldDelegateImproved: UITextFieldDelegate {
    
    @objc func textFieldDidChange(textField: UITextField)
}

class ContactCollectionViewEntryCell: UICollectionViewCell {

    var _delegate: UITextFieldDelegateImproved?
    
    private var contactEntryTextField: UITextField?
    
    @objc dynamic var font: UIFont? {
        get {
            return self.contactEntryTextField?.font
            
        }
        set {
            self.contactEntryTextField?.font = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func setup() {
        let textField = UITextField(frame: self.bounds)
        textField.delegate = self._delegate;
        textField.text = " ";
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.keyboardType = .emailAddress
        
#if DEBUG_BORDERS
        self.layer.borderColor = UIColor.orange.cgColor
        self.layer.borderWidth = 1.0;
        textField.layer.borderColor = UIColor.green.cgColor
        textField.layer.borderWidth = 2.0;
#endif

        self.addSubview(textField)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[textField]|",
                                                           options: NSLayoutFormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["textField": textField]))
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[textField]|",
                                                           options: NSLayoutFormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["textField": textField]))
        
        textField.translatesAutoresizingMaskIntoConstraints = false
    
        self.contactEntryTextField = textField
        
    }
    
    var delegate : UITextFieldDelegateImproved? {
        get {
            return _delegate
        }
        set {
            guard let textField = self.contactEntryTextField else {
                return
            }
            
            if _delegate != nil {
                textField.removeTarget(_delegate,
                                       action: #selector(UITextFieldDelegateImproved.textFieldDidChange(textField:)),
                                       for: .editingChanged)
            }
            
            _delegate = newValue;
            textField.addTarget(_delegate,
                                action: #selector(UITextFieldDelegateImproved.textFieldDidChange(textField:)),
                                for: .editingChanged)
            textField.delegate = _delegate;
        }
    }

    var text: String {
        get {
            return self.contactEntryTextField?.text ?? ""
        }
        set {
            if let textFeild = self.contactEntryTextField {
                textFeild.text = newValue
            }
        }
    }
    
    var enabled: Bool {
        get {
            return self.contactEntryTextField?.isEnabled ?? false
        }
        set {
            if let textFeild = self.contactEntryTextField {
                textFeild.isEnabled = newValue
            }
        }
    }
    
    func reset() {
         if let textfield = self.contactEntryTextField {
            textfield.text = " "
            self.delegate?.textFieldDidChange(textField: textfield)
        }
    }
    
    func setFocus() {
        if let textfield = self.contactEntryTextField {
            textfield.becomeFirstResponder()
        }
    }
    
    func removeFocus() {
        if let textfield = self.contactEntryTextField {
            textfield.resignFirstResponder()
        }
    }
    
    func widthForText(text: String) -> CGFloat {
        //        guard let font = self.contactEntryTextField?.font else {
        //            return 0.0
        //        }
        //
        //        let font = Fonts.h6.light
        //
        //        let s = CGSize(width: Double.greatestFiniteMagnitude, height: Double.greatestFiniteMagnitude)
        //        let size = NSString(string: text).boundingRect(with: s,
        //                                                       options: NSStringDrawingOptions.usesLineFragmentOrigin,
        //                                                       attributes: [NSAttributedStringKey.font : font],
        //                                                       context: nil).size
        //        return size.width.rounded(.up)
        
        return 40  //this will avoid the text input disapeared
    }
    
}





