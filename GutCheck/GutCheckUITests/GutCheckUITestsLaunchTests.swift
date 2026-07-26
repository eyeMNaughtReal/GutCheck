import XCTest

final class GutCheckUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool { true }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // App should reach either the auth screen (logged out) or main tab bar (logged in)
        let signInButton = app.buttons["SignInButton"]
        let tabBar = app.tabBars.firstMatch

        let reachedKnownState = signInButton.waitForExistence(timeout: 10) || tabBar.waitForExistence(timeout: 10)
        XCTAssertTrue(
            reachedKnownState,
            "App should display either the authentication screen or the main tab bar after launch"
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
