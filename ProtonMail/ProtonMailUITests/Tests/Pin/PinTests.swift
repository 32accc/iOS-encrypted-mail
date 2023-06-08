//
//  PinTests.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/17.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import XCTest
import ProtonCore_TestingToolkit

class PinTests: FixtureAuthenticatedTestCase {

    private let correctPin = "0000"
    private let pinRobot: PinRobot = PinRobot()
    private let inboxRobot: InboxRobot = InboxRobot()

    override func setUp() {
        super.setUp()

        runTestWithScenario(.qaMail001) {
            inboxRobot
                .menuDrawer()
                .settings()
                .pin()
                .enablePin()
                .setPin(correctPin)
        }
    }

    func testTurnOnAndOffPin() {
        pinRobot
            .disablePin()
            .verify.isPinEnabled(false)
    }

    func testEnterCorrectPinCanUnlock() {
        pinRobot
            .openPinTimerSelection()
            .selectAutolockEveryTime()
            .navigateUpToSettings()
            .close()
            .backgroundApp()
            .activateAppWithPin()
            .confirmWithEmptyPin()
            .verify.emptyPinErrorMessageShows()
            .clickOK()
            .inputCorrectPin()
            .verify.inboxShown()
    }

    func testEnterIncorrectPinCantUnlock() {
        pinRobot
            .openPinTimerSelection()
            .selectAutolockEveryTime()
            .backgroundApp()
            .activateAppWithPin()
            .inputIncorrectPin()
            .verify.pinErrorMessageShows(1)
            .inputIncorrectPin()
            .verify.pinErrorMessageShows(2)
            .logout()
            .verify.loginScreenIsShown()
    }

    func testEnterEmptyPin() {
        pinRobot
            .openPinTimerSelection()
            .selectAutolockEveryTime()
            .backgroundApp()
            .activateAppWithPin()
            .confirmWithEmptyPin()
            .verify.emptyPinErrorMessageShows()
    }

    func testEnterIncorrectPinTenTimesLogOut() {
        pinRobot
            .openPinTimerSelection()
            .selectAutolockEveryTime()
            .backgroundApp()
            .activateAppWithPin()
            .inputIncorrectPinNTimes(count: 10)
            .verify.loginScreenIsShown()
    }

    func testIncorrectPinBeforeThirtySec() {
        pinRobot
            .openPinTimerSelection()
            .selectAutolockEveryTime()
            .navigateUpToSettings()
            .close()
            .backgroundApp()
            .activateAppWithPin()
            .inputCorrectPin()
            .backgroundApp()
            .activateAppWithPin()
            .inputIncorrectPin()
            .verify.pinErrorMessageShows(1)
    }

    func testErrorMessageOnThreeRmainingPinTries() {
        pinRobot
            .openPinTimerSelection()
            .selectAutolockEveryTime()
            .navigateUpToSettings()
            .close()
            .backgroundApp()
            .activateAppWithPin()
            .inputCorrectPin()
            .backgroundApp()
            .activateAppWithPin()
            .inputIncorrectPin()
            .verify.pinErrorMessageShows(1)
            .inputIncorrectPinNTimesStayLoggedIn(count: 6)
            .verify.pinErrorMessageShowsThreeRemainingTries(3)
    }

    func testLogoutBeforeUnlockingDoesNotCrash() {
        pinRobot
            .enableAppKey()
            .openPinTimerSelection()
            .selectAutolockEveryTime()
            .foregroundApp()
            .logout()
            .verify.loginScreenIsShown()
    }

    func testEnableAutoLockPin() {
        pinRobot
            .openPinTimerSelection()
            .selectAutolockEveryTime()
            .backgroundApp()
            .activateAppWithPin()
            .verify.pinInputScreenIsShown()
    }

    func testSetPinAndLockTheAppActionInTheMenuWillLockTheApp() {
        pinRobot
            .navigateUpToSettings()
            .close()
            .menuDrawer()
            .lockTheApp()
            .verify
            .pinCodeEnterScreenIsShown()
    }
}
