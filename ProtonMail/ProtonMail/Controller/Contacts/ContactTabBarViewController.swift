//
//  ContactTabBarViewController.swift
//  ProtonMail - Created on 2018/9/4.
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

import ProtonCore_UIFoundations
import UIKit

final class ContactTabBarViewController: UITabBarController {
    var coordinator: ContactTabBarCoordinator?
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum Tab: Int {
        case contacts = 0
        case group = 1
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBar.tintColor = ColorProvider.InteractionNorm
        self.tabBar.backgroundColor = ColorProvider.BackgroundNorm
    }

    func setupViewControllers() {
        guard let views = coordinator?.makeChildViewControllers() else {
            return
        }
        self.viewControllers = views

        // setup tab bar item title
        self.tabBar.items?[0].title = LocalString._menu_contacts_title
        self.tabBar.items?[0].image = Asset.contactGroupsContactsTabbar.image
        self.tabBar.items?[0].selectedImage = Asset.contactGroupsContactsTabbarFilled.image
        self.tabBar.items?[1].title = LocalString._menu_contact_group_title
        self.tabBar.items?[1].image = Asset.contactGroupsGroupsTabbar.image
        self.tabBar.items?[1].selectedImage = Asset.contactGroupsGroupsTabbarFilled.image
        self.tabBar.assignItemsAccessibilityIdentifiers()
    }
}
