//
//  RateLimitingService.swift
//  GutCheck
//
//  Client-side rate limiting using a token-bucket algorithm.
//  Protects auth endpoints and external APIs from abuse.
//

import Foundation
import os.log

/// Errors thrown when an action is rate-limited.
enum RateLimitError: LocalizedError {
    case cooldownActive(action: String, retryAfter: TimeInterval)
    case tooManyAttempts(action: String, retryAfter: TimeInterval)

    var errorDescription: String? {
        switch self {
        case .cooldownActive(_, let retryAfter):
            let seconds = Int(ceil(retryAfter))
            return "Please wait \(seconds) second\(seconds == 1 ? "" : "s") before trying again."
        case .tooManyAttempts(_, let retryAfter):
            let seconds = Int(ceil(retryAfter))
            return "Too many attempts. Please wait \(seconds) second\(seconds == 1 ? "" : "s") before trying again."
        }
    }
}

/// Defines the rate limiting policy for a specific action.
struct RateLimitPolicy {
    /// Maximum number of tokens (requests) the bucket can hold.
    let maxTokens: Int
    /// How often a token is replenished, in seconds.
    let refillInterval: TimeInterval
    /// Minimum cooldown between consecutive calls, in seconds. 0 means no cooldown.
    let cooldownInterval: TimeInterval

    /// Auth actions: 1 request allowed, then a 60-second cooldown.
    static let authCooldown = RateLimitPolicy(maxTokens: 1, refillInterval: 60, cooldownInterval: 60)

    /// Login: 5 attempts, refill one every 30 seconds.
    static let login = RateLimitPolicy(maxTokens: 5, refillInterval: 30, cooldownInterval: 0)

    /// External API: 3 requests per second burst, refill one per second.
    static let externalAPI = RateLimitPolicy(maxTokens: 3, refillInterval: 1, cooldownInterval: 0)
}

/// In-memory token bucket for a single action.
private final class TokenBucket {
    let policy: RateLimitPolicy
    private var tokens: Double
    private var lastRefill: Date
    private var lastConsumed: Date?

    init(policy: RateLimitPolicy) {
        self.policy = policy
        self.tokens = Double(policy.maxTokens)
        self.lastRefill = Date.now
    }

    /// Attempt to consume a token. Returns nil on success, or the retry-after interval on failure.
    func consume() -> TimeInterval? {
        refill()

        // Enforce cooldown
        if policy.cooldownInterval > 0, let last = lastConsumed {
            let elapsed = Date.now.timeIntervalSince(last)
            if elapsed < policy.cooldownInterval {
                return policy.cooldownInterval - elapsed
            }
        }

        // Check token availability
        if tokens >= 1 {
            tokens -= 1
            lastConsumed = Date.now
            return nil
        }

        // No tokens available — calculate when one will be ready
        return policy.refillInterval
    }

    private func refill() {
        let now = Date.now
        let elapsed = now.timeIntervalSince(lastRefill)
        let newTokens = elapsed / policy.refillInterval
        if newTokens > 0 {
            tokens = min(Double(policy.maxTokens), tokens + newTokens)
            lastRefill = now
        }
    }
}

/// Well-known rate-limited actions.
enum RateLimitedAction: String {
    case passwordReset = "auth.passwordReset"
    case phoneVerification = "auth.phoneVerification"
    case resendVerificationEmail = "auth.resendVerificationEmail"
    case login = "auth.login"
    case foodSearchUSDA = "api.usda"
    case foodSearchOpenFoodFacts = "api.openFoodFacts"
}

/// Central rate limiting service. All state is in-memory and resets on app relaunch.
final class RateLimitingService: @unchecked Sendable {
    static let shared = RateLimitingService()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.gutcheck",
        category: "RateLimiting"
    )

    private let lock = NSLock()
    private var buckets: [String: TokenBucket] = [:]

    /// Maps well-known actions to their default policies.
    private let defaultPolicies: [RateLimitedAction: RateLimitPolicy] = [
        .passwordReset: .authCooldown,
        .phoneVerification: .authCooldown,
        .resendVerificationEmail: .authCooldown,
        .login: .login,
        .foodSearchUSDA: .externalAPI,
        .foodSearchOpenFoodFacts: .externalAPI,
    ]

    private init() {}

    // MARK: - Public API

    /// Check whether an action is allowed. Throws `RateLimitError` if not.
    func checkLimit(for action: RateLimitedAction) throws {
        let key = action.rawValue
        let policy = defaultPolicies[action] ?? .login

        lock.lock()
        let bucket = buckets[key] ?? {
            let b = TokenBucket(policy: policy)
            buckets[key] = b
            return b
        }()
        let retryAfter = bucket.consume()
        lock.unlock()

        if let retryAfter {
            logger.info("Rate limited: \(key), retry after \(retryAfter, format: .fixed(precision: 1))s")
            if policy.cooldownInterval > 0 {
                throw RateLimitError.cooldownActive(action: key, retryAfter: retryAfter)
            } else {
                throw RateLimitError.tooManyAttempts(action: key, retryAfter: retryAfter)
            }
        }
    }

    /// Record a failed attempt for actions that use progressive backoff (e.g., login).
    /// This is a no-op for cooldown-based policies.
    func recordFailure(for action: RateLimitedAction) {
        // Token is already consumed on checkLimit; no extra work needed.
        // The bucket naturally depletes on repeated failures.
    }

    /// Reset the bucket for a specific action (e.g., after successful login).
    func reset(for action: RateLimitedAction) {
        let key = action.rawValue
        let policy = defaultPolicies[action] ?? .login

        lock.lock()
        buckets[key] = TokenBucket(policy: policy)
        lock.unlock()
    }

    /// Reset all rate limit state.
    func resetAll() {
        lock.lock()
        buckets.removeAll()
        lock.unlock()
    }
}
