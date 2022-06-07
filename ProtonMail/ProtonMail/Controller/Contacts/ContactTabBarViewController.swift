//
//  ContactTabBarViewController.swift
//  Proton Mail - Created on 2018/9/4.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import ProtonCore_UIFoundations

class ContactTabBarViewController: UITabBarController, CoordinatedNew {
    typealias coordinatorType = ContactTabBarCoordinator
    private var coordinator: ContactTabBarCoordinator?
    func set(coordinator: ContactTabBarCoordinator) {
        self.coordinator = coordinator
    }
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }

    enum Tab: Int {
        case contacts = 0
        case group = 1
    }

    var groupsViewController: ContactGroupsViewController? {
        get {
            let index = Tab.group.rawValue
            if let viewControllers = self.viewControllers, viewControllers.count > index,
                let navigation = viewControllers[index] as? UINavigationController,
                let viewController = navigation.firstViewController() as? ContactGroupsViewController {
                return viewController
            }
            return nil
        }
    }

    var contactsViewController: ContactsViewController? {
        get {
            let index = Tab.contacts.rawValue
            if let viewControllers = self.viewControllers, viewControllers.count > index,
                let navigation = viewControllers[index] as? UINavigationController,
                let viewController = navigation.firstViewController() as? ContactsViewController {
                return viewController
            }
            return nil
        }
    }

    class func instance() -> ContactTabBarViewController {
        let board = UIStoryboard.Storyboard.contact.storyboard
        let vc = board.instantiateInitialViewController() as! ContactTabBarViewController
        return vc
    }

    ///    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBar.tintColor = ColorProvider.InteractionNorm
        self.tabBar.backgroundColor = ColorProvider.BackgroundNorm
        // setup tab bar item title
        self.tabBar.items?[0].title = LocalString._menu_contacts_title
        self.tabBar.items?[0].image = IconProvider.user
        self.tabBar.items?[0].selectedImage = IconProvider.userFilled
        self.tabBar.items?[1].title = LocalString._menu_contact_group_title
        self.tabBar.items?[1].image = IconProvider.users
        self.tabBar.items?[1].selectedImage = IconProvider.usersFilled
        self.tabBar.assignItemsAccessibilityIdentifiers()
    }
}
