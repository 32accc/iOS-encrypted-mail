//
//  PinTests.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/17.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest
import ProtonCore_TestingToolkit

class PinTests: BaseTestCase {
    private let pinRobot: PinRobot = PinRobot()
    private let loginRobot = LoginRobot()
    let correctPins = [0,1,2,3,4,5,6,7,8,9]
    let incorrectPins = [1,2]
    
    override func setUp() {
        super.setUp()
        loginRobot
            .loginUser(testData.onePassUser)
            .menuDrawer()
            .settings()
            .pin()
            .enablePin().setPin(pin: "\(correctPins)")
            .verify.isPinEnabled(true)
    }
    
    func testTurnOnAndOffPin() {
        pinRobot
            .disablePin()
            .verify.isPinEnabled(false)
    }
    
    func testEnterCorrectPinCanUnlock() {
        pinRobot
            .backgroundApp()
            .foregroundApp()
            .confirmWithEmptyPin()
            .verify.emptyPinErrorMessageShows()
            .clickOK()
            .inputCorrectPin(correctPins)
            .verify.appUnlockSuccessfully()
    }
    
    func testEnterIncorrectPinCantUnlock() {
        pinRobot
            .backgroundApp()
            .foregroundApp()
            .inputIncorrectPin(incorrectPins)
            .verify.pinErrorMessageShows(1)
            .inputIncorrectPin(incorrectPins)
            .verify.pinErrorMessageShows(2)
            .logout()
            .verify.loginScreenIsShown()
    }
}
