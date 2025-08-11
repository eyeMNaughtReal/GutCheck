import SwiftUI

@MainActor
class RefreshManager: ObservableObject {
    static let shared = RefreshManager()
    
    @Published var refreshToken = UUID()
    @Published var isRefreshing = false
    
    private init() {}
    
    func triggerRefresh() {
        refreshToken = UUID() // This will trigger any views observing this value
    }
    
    func triggerRefreshAfterSave() {
        // Wait a short moment to allow database operations to complete
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            triggerRefresh()
        }
    }
    
    // For UI loading indicators
    func withRefreshingState<T>(_ operation: () async throws -> T) async throws -> T {
        isRefreshing = true
        defer { isRefreshing = false }
        return try await operation()
    }
}
