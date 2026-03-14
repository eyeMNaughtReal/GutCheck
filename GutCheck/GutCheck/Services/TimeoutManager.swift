import Foundation
import SwiftUI

@MainActor
@Observable class TimeoutManager {
    static let shared = TimeoutManager()
    
    private(set) var shouldResetToHome = false
    private var backgroundEnteredTime: Date?
    private let timeoutInterval: TimeInterval = 300 // 5 minutes in seconds
    
    private init() {}
    
    func applicationDidEnterBackground() {
        backgroundEnteredTime = Date.now
    }
    
    func applicationWillEnterForeground() {
        guard let backgroundTime = backgroundEnteredTime else { return }
        
        let timeInBackground = Date.now.timeIntervalSince(backgroundTime)
        if timeInBackground >= timeoutInterval {
            shouldResetToHome = true
        }
        
        backgroundEnteredTime = nil
    }
    
    func resetTimeoutState() {
        shouldResetToHome = false
        backgroundEnteredTime = nil
    }
}
