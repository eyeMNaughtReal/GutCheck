import XCTest

final class AuthenticationViewUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testAuthenticationScreenElements() throws {
        // Check for email field
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.exists, "Email field should exist")
        
        // Check for password field
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.exists, "Password field should exist")
        
        // Check for sign in button
        let signInButton = app.buttons["Sign In"]
        XCTAssertTrue(signInButton.exists, "Sign In button should exist")
        
        // Check for phone sign-in button
        let phoneButton = app.buttons["Phone"]
        XCTAssertTrue(phoneButton.exists, "Phone sign-in button should exist")
    }
    
    func testSignInButtonDisabledWhenFieldsEmpty() throws {
        let signInButton = app.buttons["Sign In"]
        XCTAssertFalse(signInButton.isEnabled, "Sign In button should be disabled when fields are empty")
    }
}
