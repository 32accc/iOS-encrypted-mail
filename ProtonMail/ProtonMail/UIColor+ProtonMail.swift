//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

import Foundation
import UIKit

extension UIColor {
    
    convenience init(RRGGBB: UInt, alpha: CGFloat) {
        self.init(
            red: CGFloat((RRGGBB & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((RRGGBB & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(RRGGBB & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
    
    convenience init(RRGGBB: UInt) {
        self.init(
            red: CGFloat((RRGGBB & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((RRGGBB & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(RRGGBB & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
    
    internal struct ProtonMail {
        static let Blue_475F77 = UIColor(RRGGBB: UInt(0x475F77))
        static let Blue_5C7A99 = UIColor(RRGGBB: UInt(0x5C7A99))
        static let Blue_6789AB = UIColor(RRGGBB: UInt(0x6789AB))
        static let Gray_FCFEFF = UIColor(RRGGBB: UInt(0xFCFEFF))
        static let Gray_E8EBED = UIColor(RRGGBB: UInt(0xE8EBED))
        static let Gray_999DA1 = UIColor(RRGGBB: UInt(0x999DA1))
    }    
}