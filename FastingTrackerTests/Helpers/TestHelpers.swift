//
//  TestHelpers.swift
//  FastingTrackerTests
//
//  Created by Claude Code
//  Phase 0: Test Helper Utilities
//

import Foundation
import XCTest
@testable import FastingTracker

// MARK: - Date Helpers

extension Date {
    /// Creates a date from components for testing
    static func testDate(year: Int = 2025, month: Int = 10, day: Int = 17, hour: Int = 12, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    /// Returns date minus specified hours
    func minusHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: -hours, to: self) ?? self
    }

    /// Returns date plus specified hours
    func plusHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    /// Returns date minus specified days
    func minusDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }

    /// Returns date plus specified days
    func plusDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}

// MARK: - XCTest Assertions

extension XCTestCase {
    /// Asserts two dates are equal within a tolerance (default 1 second)
    func XCTAssertEqualDates(_ date1: Date, _ date2: Date, accuracy: TimeInterval = 1.0, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
        let difference = abs(date1.timeIntervalSince(date2))
        XCTAssertLessThanOrEqual(difference, accuracy, "Dates not equal within \(accuracy)s tolerance: \(message)", file: file, line: line)
    }

    /// Asserts a value is within a percentage of expected (for floating point comparisons)
    func XCTAssertEqualWithin(_ value: Double, _ expected: Double, percent: Double = 0.01, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
        let difference = abs(value - expected)
        let tolerance = expected * percent
        XCTAssertLessThanOrEqual(difference, tolerance, "Value \(value) not within \(percent*100)% of \(expected): \(message)", file: file, line: line)
    }
}

// MARK: - Mock Data Generators

enum TestDataGenerator {
    /// Generates an array of test dates spanning a range
    static func dateRange(from start: Date, count: Int, intervalHours: Int = 24) -> [Date] {
        (0..<count).map { index in
            start.plusHours(index * intervalHours)
        }
    }

    /// Generates random hydration amounts for testing
    static func randomHydrationAmounts(count: Int, min: Double = 100, max: Double = 500) -> [Double] {
        (0..<count).map { _ in
            Double.random(in: min...max)
        }
    }

    /// Generates random weight values for testing
    static func randomWeights(count: Int, baseWeight: Double = 70.0, variance: Double = 2.0) -> [Double] {
        (0..<count).map { _ in
            baseWeight + Double.random(in: -variance...variance)
        }
    }
}
