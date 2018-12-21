//
//  ServicePlanFooter.swift
//  ProtonMail - Created on 12/08/2018.
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


import UIKit

class ServicePlanFooter: UIView {

    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var buyButton: UIButton!
    @IBOutlet private weak var subtitle: UILabel!
    private var buttonAction: ((UIButton?)->Void)?
    
    override func prepareForInterfaceBuilder() {
        self.setupSubviews()
    }
    
    convenience init(title: NSAttributedString? = nil,
                     subTitle: String? = nil,
                     buttonTitle: NSAttributedString? = nil,
                     buttonEnabled: Bool = true,
                     buttonAction: ((UIButton?)->Void)?=nil)
    {
        self.init(frame: .zero)
        defer {
            self.setup(title: title, subTitle: subTitle, buttonTitle: buttonTitle, buttonEnabled: buttonEnabled, buttonAction: buttonAction)
        }
    }
    
    func setup(title: NSAttributedString? = nil,
               subTitle: String? = nil,
               buttonTitle: NSAttributedString? = nil,
               buttonEnabled: Bool = true,
               buttonAction: ((UIButton?)->Void)?=nil)
    {
        self.title.attributedText = title
        self.subtitle.text = subTitle
        
        if buttonTitle != nil {
            self.buyButton.setAttributedTitle(buttonTitle, for: .normal)
            self.buyButton.titleLabel?.numberOfLines = 0
            self.buyButton.titleLabel?.lineBreakMode = .byWordWrapping
            self.buyButton.titleLabel?.textAlignment = .center
            self.buttonAction = buttonAction
            self.buyButton.addTarget(self, action: #selector(self.performButtonAction), for: .touchUpInside)
            self.style(buttonEnabled: buttonEnabled)
        } else {
            self.buyButton.isHidden = true
        }
    }
    
    private func style(buttonEnabled: Bool) {
        DispatchQueue.main.async {
            self.buyButton.isUserInteractionEnabled = buttonEnabled
            self.buyButton.backgroundColor = buttonEnabled ? UIColor.ProtonMail.ButtonBackground : UIColor.ProtonMail.TableSeparatorGray
        }
    }
    
    @objc private func performButtonAction() {
        self.style(buttonEnabled: false)
        self.buttonAction?(self.buyButton)
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadFromNib()
        self.setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadFromNib()
        self.setupSubviews()
    }
    
    private func setupSubviews() {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.buyButton.roundCorners()
        self.buyButton.backgroundColor = UIColor.ProtonMail.ButtonBackground
    }
}
