//
//  LabelFolderTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 13.11.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import ProtonCore_TestingToolkit

class LabelsFoldersTests: BaseTestCase {
    
    private let accountSettingsRobot: AccountSettingsRobot = AccountSettingsRobot()
    private let loginRobot = LoginRobot()
    
    func testCreateAndDeleteCustomFolder() {
        let user = testData.onePassUser
        let folderName = StringUtils().randomAlphanumericString()
        
        loginRobot
            .loginUser(user)
            .refreshMailbox()
            .clickMessageByIndex(1)
            .createFolder(folderName)
            .clickApplyButtonAndReturnToInbox()
            .menuDrawer()
            .settings()
            .selectAccount(user.email)
            .folders()
            .deleteFolderLabel(folderName)
            .folders()
            .verify.folderLabelDeleted(folderName)
    }
    
    func testCreateAndDeleteCustomLabel() {
        let user = testData.onePassUser
        let labelName = StringUtils().randomAlphanumericString()
        
        loginRobot
            .loginUser(user)
            .refreshMailbox()
            .clickMessageByIndex(1)
            .createLabel(labelName)
            .clickLabelApplyButton()
            .navigateBackToInbox()
            .menuDrawer()
            .settings()
            .selectAccount(user.email)
            .labels()
            .deleteFolderLabel(labelName)
            .labels()
            .verify.folderLabelDeleted(labelName)
    }
    
    func testAddMessageToCustomFolderFromInbox() {
        let user = testData.onePassUser
        let secondUser = testData.twoPassUser
        let to = secondUser.email
        let subject = testData.messageSubject
        let folderName = "TestAutomationFolder"
        
        loginRobot
            .loginUser(user)
            .compose()
            .sendMessage(to, subject)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(secondUser)
            .clickMessageBySubject(subject)
            .addMessageToFolder(folderName)
            .menuDrawer()
            .folderOrLabel(folderName)
            .verify.messageExists(subject)
    }
    
    func testAddMessageToCustomLabelFromInbox() {
        let user = testData.onePassUser
        let secondUser = testData.twoPassUser
        let to = secondUser.email
        let subject = testData.messageSubject
        let labelName = "TestAutomationLabel"
        
        loginRobot
            .loginUser(user)
            .compose()
            .sendMessage(to, subject)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(secondUser)
            .clickMessageBySubject(subject)
            .assignLabelToMessage(labelName)
            .navigateBackToInbox()
            .menuDrawer()
            .folderOrLabel(labelName)
            .verify.messageExists(subject)
    }
    
    func testEditCustomFolderNameAndColor() {
        let user = testData.onePassUser
        let folderName = StringUtils().randomAlphanumericString()
        let newFolderName = StringUtils().randomAlphanumericString()
        
        loginRobot
            .loginUser(user)
            .refreshMailbox()
            .clickMessageByIndex(1)
            .createFolder(folderName)
            .clickApplyButtonAndReturnToInbox()
            .menuDrawer()
            .settings()
            .selectAccount(user.email)
            .folders()
            .editFolderLabel(folderName)
            .editFolderLabelName(newFolderName)
            .selectFolderColorByIndex(3)
            .done()
            .create()
            .deleteFolderLabel(newFolderName)
            .folders()
            .verify.folderLabelDeleted(newFolderName)
    }
    
    func testEditCustomLabelNameAndColor() {
        let user = testData.onePassUser
        let folderName = StringUtils().randomAlphanumericString()
        let newFolderName = StringUtils().randomAlphanumericString()
        
        loginRobot
            .loginUser(user)
            .refreshMailbox()
            .clickMessageByIndex(1)
            .createLabel(folderName)
            .clickLabelApplyButton()
            .navigateBackToInbox()
            .menuDrawer()
            .settings()
            .selectAccount(user.email)
            .labels()
            .editFolderLabel(folderName)
            .editFolderLabelName(newFolderName)
            .selectFolderColorByIndex(3)
            .done()
            .create()
            .deleteFolderLabel(newFolderName)
            .labels()
            .verify.folderLabelDeleted(newFolderName)
    }
}
