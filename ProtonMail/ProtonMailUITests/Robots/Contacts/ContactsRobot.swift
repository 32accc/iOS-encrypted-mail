//
//  ContactsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 05.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let addContactAlertButtonText = LocalString._contacts_add_contact
fileprivate let addGroupAlertButtonText = LocalString._contact_groups_add
fileprivate let deleteContactAlertButtonText = LocalString._delete_contact
fileprivate let deleteGroupAlertButtonText = LocalString._contact_groups_delete
fileprivate let deleteButtonText = LocalString._general_delete_action
fileprivate let contactsTabBarButtonIdentifier = "UITabBar.\(LocalString._contacts_title)"
fileprivate let groupsTabBarButtonIdentifier = "UITabBar.\(LocalString._menu_contact_group_title)"
fileprivate func contactCellIdentifier(_ email: String) -> String { return "ContactsTableViewCell.\(email)" }
fileprivate func groupCellIdentifier(_ name: String) -> String { return "ContactGroupsViewCell.\(name)" }
fileprivate func groupCellSendImailImageIdentifier(_ name: String) -> String { return "\(name).sendButtonImage" }
fileprivate let menuNavBarButtonIdentifier = "UINavigationItem.revealToggle"
fileprivate let addContactNavBarButtonIdentifier = "UINavigationItem.addButton"
fileprivate let importContactNavBarButtonIdentifier = "UINavigationItem.importButton"
fileprivate let contactsTableViewIdentifier = "ContactsViewController.tableView"

/**
 ContactsRobot class contains actions and verifications for Contacts functionality.
 */
class ContactsRobot {
    
    var verify: Verify! = nil
    init() { verify = Verify() }

    func addContact() -> AddContactRobot {
        return add().contact()
    }

    func addGroup() -> AddContactGroupRobot {
        return add().group()
    }

    func groupsView() -> ContactsGroupView {
        Element.wait.forButtonWithIdentifier(groupsTabBarButtonIdentifier).tap()
        return ContactsGroupView()
    }

    func contactsView() -> ContactsView {
        Element.wait.forButtonWithIdentifier(contactsTabBarButtonIdentifier).tap()
        return ContactsView()
    }

    func menuDrawer() -> MenuRobot {
        Element.button.tapByIdentifier(menuNavBarButtonIdentifier)
        return MenuRobot()
    }
    
    private func add() -> ContactsRobot {
        Element.wait.forButtonWithIdentifier(addContactNavBarButtonIdentifier).tap()
        return ContactsRobot()
    }
    
    private func contact() -> AddContactRobot {
        Element.wait.forButtonWithIdentifier(addContactAlertButtonText).tap()
        return AddContactRobot()
    }
    
    private func group() -> AddContactGroupRobot {
        Element.wait.forButtonWithIdentifier(addGroupAlertButtonText).tap()
        return AddContactGroupRobot()
    }

    class ContactsView {
        
        var verify: Verify! = nil
        init() { verify = Verify() }
        
        func deleteContact(_ withEmail: String) -> ContactsView {
            return swipeLeftToDelete(withEmail)
                .clickDeleteButton()
                .confirmDeletion()
        }

        func clickContact(_ withEmail: String) -> ContactDetailsRobot {
            Element.wait.forCellWithIdentifier(contactCellIdentifier(withEmail)).tap()
            return ContactDetailsRobot()
        }
        
        private func swipeLeftToDelete(_ withEmail: String) -> ContactsView {
            Element.cell.swipeDownUpUntilVisibleByIdentifier(contactCellIdentifier(withEmail)).swipeLeft()
            return ContactsView()
        }
        
        private func clickDeleteButton() -> ContactsView {
            Element.wait.forButtonWithIdentifier(deleteButtonText).tap()
            return ContactsView()
        }
        
        private func confirmDeletion() -> ContactsView {
            Element.wait.forButtonWithIdentifier(deleteContactAlertButtonText).tap()
            return self
        }
        
        class Verify {

            func contactExists(_ email: String) {
                Element.wait.forCellWithIdentifier(contactCellIdentifier(email))
            }

            func contactDoesNotExists(_ email: String) {
                Element.wait.forCellWithIdentifierToDisappear(contactCellIdentifier(email))
            }
        }
    }

    class ContactsGroupView {
        
        var verify: Verify! = nil
        init() { verify = Verify() }

        func clickGroup(_ withName: String) -> GroupDetailsRobot {
            Element.cell.swipeSwipeUpUntilVisibleByIdentifier(groupCellIdentifier(withName)).tap()
            return GroupDetailsRobot()
        }

        func deleteGroup(_ withName: String) -> ContactsGroupView {
            return swipeLeftToDelete(withName)
                .clickDeleteButton()
                .confirmDeletion()
        }
        
        func sendGroupEmail(_ name: String) -> ComposerRobot {
            Element.wait.forImageWithIdentifier(groupCellSendImailImageIdentifier(name), file: #file, line: #line).tap()
            return ComposerRobot()
        }
        
        private func swipeLeftToDelete(_ withName: String) -> ContactsGroupView {
            Element.cell.swipeDownUpUntilVisibleByIdentifier(groupCellIdentifier(withName)).swipeLeft()
            return self
        }
        
        private func clickDeleteButton() -> ContactsGroupView {
            Element.wait.forButtonWithIdentifier(deleteButtonText, file: #file, line: #line).tap()
            return self
        }
        
        private func confirmDeletion() -> ContactsGroupView {
            Element.wait.forButtonWithIdentifier(deleteGroupAlertButtonText, file: #file, line: #line).tap()
            return self
        }

        class Verify {

            func groupDoesNotExists(_ name: String) {
                Element.wait.forCellWithIdentifierToDisappear(groupCellIdentifier(name), file: #file, line: #line)
            }
        }
    }

    /**
     * Contains all the validations that can be performed by [ContactsRobot].
     */
    class Verify {

        func contactsOpened() {
            Element.wait.forTableViewWithIdentifier(contactsTableViewIdentifier, file: #file, line: #line)
        }
    }
}
