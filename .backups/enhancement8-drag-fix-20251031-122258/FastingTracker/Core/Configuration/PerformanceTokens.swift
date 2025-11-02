//
// PerformanceTokens.swift
// FastingTracker
//
// Created for LifeGPT Performance Optimization
// Single source of truth for performance thresholds, cache TTLs, query timeouts
// Reference: SESSION-PREFERENCES.md - Always use tokens for centralized constants
//

import Foundation

/// Performance tokens for LifeGPT intelligence layer
/// **Single Source of Truth:** All performance-related constants centralized here
/// **Industry Pattern:** Apple, Whoop, Oura use aggressive caching for repeated queries
enum PerformanceTokens {

    // MARK: - Cache TTL (Time To Live)

    /// How long to cache query results before refreshing
    /// **Apple Pattern:** Siri caches repeated queries for 60s
    /// **Whoop Pattern:** Recovery score cached for 5 minutes
    /// **Oura Pattern:** Readiness score cached for 60s
    static let queryCacheTTL: TimeInterval = 60.0  // 60 seconds

    /// How long to cache insight context (health data snapshot)
    /// **Industry Standard:** 30-60s for aggregated metrics
    static let insightContextCacheTTL: TimeInterval = 30.0  // 30 seconds

    // MARK: - Query Timeouts

    /// Maximum time to wait for HealthKit query before timeout
    /// **Apple Pattern:** HealthKit queries should complete in <500ms
    static let healthKitQueryTimeout: TimeInterval = 2.0  // 2 seconds (conservative)

    /// Maximum time for full intelligence pipeline execution
    /// **Target:** <1s for production-grade experience
    static let intelligencePipelineTimeout: TimeInterval = 3.0  // 3 seconds (fallback to Phase 1 after)

    // MARK: - Batch Query Limits

    /// Maximum number of weight entries to fetch in a single query
    /// **Balance:** Enough data for analysis, not too much for performance
    static let maxWeightEntriesPerQuery: Int = 365  // 1 year of daily entries

    /// Maximum number of fasting sessions to fetch in a single query
    /// **Balance:** Enough for streak/frequency calculations
    static let maxFastingSessionsPerQuery: Int = 100  // ~3 months of daily fasts

    // MARK: - Performance Targets

    /// Target response time for simple queries (e.g., "What's my weight?")
    /// **Industry Standard:** <1s for instant feel
    static let targetSimpleQueryTime: TimeInterval = 0.5  // 500ms

    /// Target response time for complex queries (e.g., "Goal ETA with trend analysis?")
    /// **Industry Standard:** <2s for complex analytics
    static let targetComplexQueryTime: TimeInterval = 1.5  // 1.5 seconds

    /// Target response time for insight generation (EmotionEngine + InsightGenerator)
    /// **Industry Standard:** <500ms for rule-based intelligence
    static let targetInsightGenerationTime: TimeInterval = 0.5  // 500ms
}

/// Cache entry with expiration tracking
struct CacheEntry<T> {
    let value: T
    let timestamp: Date
    let ttl: TimeInterval

    /// Check if cache entry is still valid (not expired)
    var isValid: Bool {
        return Date().timeIntervalSince(timestamp) < ttl
    }
}

/// Simple thread-safe cache for query results
actor QueryCache {
    /// Singleton instance for global cache access
    static let shared = QueryCache()

    private var cache: [String: Any] = [:]

    /// Store value in cache with TTL
    /// - Parameters:
    ///   - value: Value to cache
    ///   - key: Cache key (use query string or intent description)
    ///   - ttl: Time to live in seconds (default: PerformanceTokens.queryCacheTTL)
    func set<T>(_ value: T, forKey key: String, ttl: TimeInterval = PerformanceTokens.queryCacheTTL) {
        let entry = CacheEntry(value: value, timestamp: Date(), ttl: ttl)
        cache[key] = entry
    }

    /// Retrieve value from cache if valid (not expired)
    /// - Parameter key: Cache key
    /// - Returns: Cached value if valid, nil if expired or not found
    func get<T>(forKey key: String) -> T? {
        guard let entry = cache[key] as? CacheEntry<T> else {
            return nil
        }

        // Check if expired
        if !entry.isValid {
            cache.removeValue(forKey: key)
            return nil
        }

        return entry.value
    }

    /// Clear all cached entries
    func clearAll() {
        cache.removeAll()
    }

    /// Clear expired entries (periodic cleanup)
    func clearExpired() {
        cache = cache.filter { key, value in
            guard let entry = value as? CacheEntry<Any> else { return false }
            return entry.isValid
        }
    }
}
