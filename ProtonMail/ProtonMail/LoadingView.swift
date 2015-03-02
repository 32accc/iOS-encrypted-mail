//
//  LoadingView.swift
//  ProtonMail
//
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

class LoadingView: UIView {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingLabel: UILabel!
    
    class func viewForOwner(owner: AnyObject?) -> LoadingView {
        let objects = NSBundle.mainBundle().loadNibNamed("LoadingView", owner: owner, options: nil)
        for object in objects {
            if let view = object as? LoadingView {
                return view
            }
        }
        
        assertionFailure("LoadingView did not load from nib!")
        return LoadingView()
    }
}
