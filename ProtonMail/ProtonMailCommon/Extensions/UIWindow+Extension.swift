//
//  UIWindow+Extension.swift
//  ProtonMail - Created on 22/11/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import SideMenuSwift

extension UIWindow {
    func enumerateViewControllerHierarchy(_ handler: @escaping (UIViewController, inout Bool) -> Void) {
        var stop: Bool = false
        var currentController = self.rootViewController

        while !stop {
            if let nextViewController = currentController as? SideMenuController {
                handler(nextViewController.menuViewController, &stop)
                handler(nextViewController.contentViewController, &stop)
                currentController = nextViewController.contentViewController
                continue
            }

            if let nextViewController = currentController as? UINavigationController {
                handler(nextViewController, &stop)
                nextViewController.viewControllers.forEach { handler($0, &stop) }
                currentController = nextViewController.topViewController
                continue
            }

            if let nextViewController = currentController?.presentedViewController {
                handler(nextViewController, &stop)
                currentController = nextViewController
                continue
            }

            stop = true
        }
    }

    func topmostViewController() -> UIViewController? {
        var topController = self.rootViewController
        while let presentedViewController = topController?.presentedViewController
            ?? (topController as? SideMenuController)?.contentViewController
            ?? (topController as? UINavigationController)?.topViewController {
            topController = presentedViewController
        }
        return topController
    }

    convenience init(storyboard: UIStoryboard.Storyboard, scene: AnyObject?) {
        guard let root = UIStoryboard.instantiateInitialViewController(storyboard: storyboard) else {
            assert(false, "No initial VC in storyboard \(storyboard.restorationIdentifier)")
            self.init(frame: .zero)
            return
        }
        self.init(root: root, scene: scene)
    }

    convenience init(root: UIViewController, scene: AnyObject?) {
        if #available(iOS 13.0, *), let scene = scene as? UIWindowScene {
            self.init(windowScene: scene)
        } else {
            self.init(frame: UIScreen.main.bounds)
        }
        self.rootViewController = root
    }
}
