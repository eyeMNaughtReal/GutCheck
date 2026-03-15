import XCTest

final class AuthenticationViewUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    func testAuthenticationScreenElements() throws {
        // Check for email field
        let emailField = app.textFields["EmailField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5), "Email field should exist")
        
        // Check for password field
        let passwordField = app.secureTextFields["PasswordField"]
        XCTAssertTrue(passwordField.exists, "Password field should exist")
        
        // Check for sign in button
        let signInButton = app.buttons["SignInButton"]
        XCTAssertTrue(signInButton.exists, "Sign In button should exist")
    }
    
    func testSignInButtonDisabledWhenFieldsEmpty() throws {
        let signInButton = app.buttons["SignInButton"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Sign In button should exist")
        XCTAssertFalse(signInButton.isEnabled, "Sign In button should be disabled when fields are empty")
    }
}
