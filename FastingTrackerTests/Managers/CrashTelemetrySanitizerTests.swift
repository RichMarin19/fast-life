import XCTest
@testable import FastLIFe

final class CrashTelemetrySanitizerTests: XCTestCase {

    func testSanitizeContextRedactsSensitiveValues() {
        let context: [String: Any] = [
            "weight": 182.4,
            "goalWeight": "170 lbs",
            "description": "Sync failed for weight entry",
            "nested": ["weightChange": -2.3]
        ]

        let sanitized = CrashTelemetrySanitizer.sanitizeContext(context)

        XCTAssertEqual(sanitized["weight"] as? String, "[REDACTED]")
        XCTAssertEqual(sanitized["goalWeight"] as? String, "[REDACTED]")
        XCTAssertTrue(sanitized["containsSensitiveTelemetry"] as? Bool ?? false)

        if let nested = sanitized["nested"] as? String {
            XCTAssertFalse(nested.contains("2.3"))
        } else {
            XCTFail("Nested dictionary should be stringified")
        }
    }

    func testSanitizeMessageRedactsUnits() {
        let message = "Manual sync failed with weight 180.2 lbs and goal 170 lbs"
        let sanitized = CrashTelemetrySanitizer.sanitizeMessage(message)

        XCTAssertFalse(sanitized.lowercased().contains("lbs"))
        XCTAssertFalse(sanitized.contains("180.2"))
        XCTAssertFalse(sanitized.contains("170"))
    }

    func testSanitizeMessageRedactsTokenWords() {
        let message = "Goal weight authorization required"
        let sanitized = CrashTelemetrySanitizer.sanitizeMessage(message)

        XCTAssertFalse(sanitized.lowercased().contains("goal weight"))
        XCTAssertTrue(sanitized.contains("[REDACTED]"))
    }

    func testSanitizeContextHandlesNestedCollections() {
        let context: [String: Any] = [
            "metadata": [
                "weights": [182.1, 181.8, 181.2],
                "notes": ["goal weight met", "hydration 80 oz"]
            ],
            "history": [["weight": 178.4], ["weight": 179.0]]
        ]

        let sanitized = CrashTelemetrySanitizer.sanitizeContext(context)

        if let metadata = sanitized["metadata"] as? String {
            XCTAssertFalse(metadata.contains("182.1"))
            XCTAssertFalse(metadata.lowercased().contains("hydration"))
        } else {
            XCTFail("Metadata should be stringified summary")
        }

        if let history = sanitized["history"] as? String {
            XCTAssertFalse(history.contains("178.4"))
            XCTAssertFalse(history.contains("179.0"))
        } else {
            XCTFail("History should be stringified summary")
        }
    }

    func testSanitizedDescriptionRedactsNSErrorUserInfo() {
        let nsError = NSError(
            domain: "com.fastlife.weight",
            code: 42,
            userInfo: [
                "weight": "180 lbs",
                "reason": "Goal weight mismatch"
            ]
        )

        let description = CrashTelemetrySanitizer.sanitizedDescription(for: nsError, category: "weight")

        XCTAssertFalse(description.lowercased().contains("180"))
        XCTAssertFalse(description.lowercased().contains("lbs"))
        XCTAssertFalse(description.lowercased().contains("goal weight"))
        XCTAssertTrue(description.contains("#42"))
    }

    func testSanitizedNSErrorRedactsUserInfoPayload() {
        let nsError = NSError(
            domain: "com.fastlife.weight",
            code: 99,
            userInfo: [
                "goalWeight": 170,
                "debug": "weight=180"
            ]
        )

        let sanitized = CrashTelemetrySanitizer.sanitizedNSError(from: nsError)

        XCTAssertEqual(sanitized.domain, nsError.domain)
        XCTAssertEqual(sanitized.code, nsError.code)
        XCTAssertEqual(sanitized.userInfo["goalWeight"] as? String, "[REDACTED]")
        XCTAssertEqual(sanitized.userInfo["debug"] as? String, "[REDACTED]")
    }
}
