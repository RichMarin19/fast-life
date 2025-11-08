import XCTest

/// Guards against accidental `.public` privacy annotations in app logging.
/// To keep the Fast LIFe weight stack compliant, only `AppLogger` itself
/// should define public payload helpers; call sites must rely on the
/// `.private` default or the explicit public wrappers.
final class AppLoggerPrivacyTests: XCTestCase {

    func testNoPublicPrivacyAnnotationsInAppSources() throws {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let testsRoot = testsDirectory.deletingLastPathComponent()
        let projectRoot = testsRoot.deletingLastPathComponent()
        let sourceRoot = projectRoot.appendingPathComponent("FastingTracker")

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: sourceRoot,
            includingPropertiesForKeys: nil
        ) else {
            XCTFail("Failed to enumerate source files at \(sourceRoot.path)")
            return
        }

        let rootPrefix = projectRoot.path + "/"
        let allowedPublicPrivacyFiles: Set<String> = [
            "FastingTracker/Core/Utilities/AppLogger.swift",
            "FastingTracker/Core/Managers/Weight/WeightTrackerMetrics.swift"
        ]

        var privacyViolations: [String] = []
        var payloadViolations: [String] = []
        var crashlyticsViolations: [String] = []
        var crashlyticsImportViolations: [String] = []
        let weightInterpolationRegex = try NSRegularExpression(
            pattern: #"\\\([^)]*weight"#,
            options: []
        )
        let appLoggerUnitRegex = try NSRegularExpression(
            pattern: #"AppLogger\.(?:info|debug|warning|error).*?\b(lbs|pounds|kg|kilograms)\b"#,
            options: [.caseInsensitive]
        )
        let crashlyticsCallRegex = try NSRegularExpression(
            pattern: #"Crashlytics\.crashlytics\("#,
            options: []
        )

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "swift" else { continue }
            if fileURL.path.contains("/Legacy/") { continue }

            let relativePath = fileURL.path.replacingOccurrences(of: rootPrefix, with: "")
            let contents = try String(contentsOf: fileURL, encoding: .utf8)

            if !allowedPublicPrivacyFiles.contains(relativePath),
               contents.contains("privacy: .public") {
                privacyViolations.append(relativePath)
            }

            appendCrashlyticsViolationsIfNeeded(
                contents: contents,
                relativePath: relativePath,
                crashlyticsViolations: &crashlyticsViolations,
                crashlyticsImportViolations: &crashlyticsImportViolations,
                crashlyticsCallRegex: crashlyticsCallRegex
            )

            if relativePath.hasSuffix("AppLogger.swift") { continue }

            let lines = contents.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() where line.contains("AppLogger") {
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                if appLoggerUnitRegex.firstMatch(in: line, options: [], range: range) != nil ||
                    weightInterpolationRegex.firstMatch(in: line, options: [], range: range) != nil {
                    payloadViolations.append("\(relativePath):\(index + 1)")
                }
            }
        }

        XCTAssertTrue(
            privacyViolations.isEmpty,
            """
            `.public` privacy annotations are restricted to AppLogger helpers.
            Found unexpected usage in:
            \(privacyViolations.joined(separator: "\n"))
            """
        )

        XCTAssertTrue(
            payloadViolations.isEmpty,
            """
            AppLogger call-sites must not log raw weight values or explicit units.
            Remove or redact the following occurrences:
            \(payloadViolations.joined(separator: "\n"))
            """
        )

        XCTAssertTrue(
            crashlyticsViolations.isEmpty,
            """
            Crashlytics interactions must go through CrashReportManager sanitizers.
            Replace direct usage in:
            \(crashlyticsViolations.joined(separator: "\n"))
            """
        )

        XCTAssertTrue(
            crashlyticsImportViolations.isEmpty,
            """
            Only CrashReportManager may import FirebaseCrashlytics directly.
            Remove these imports:
            \(crashlyticsImportViolations.joined(separator: "\n"))
            """
        )
    }
}

// MARK: - Helpers

private func appendCrashlyticsViolationsIfNeeded(
    contents: String,
    relativePath: String,
    crashlyticsViolations: inout [String],
    crashlyticsImportViolations: inout [String],
    crashlyticsCallRegex: NSRegularExpression
) {
    if relativePath.hasSuffix("CrashReportManager.swift") { return }

    if contents.contains("import FirebaseCrashlytics") {
        crashlyticsImportViolations.append(relativePath)
    }

    let fileRange = NSRange(location: 0, length: (contents as NSString).length)
    if crashlyticsCallRegex.firstMatch(in: contents, options: [], range: fileRange) != nil {
        crashlyticsViolations.append(relativePath)
    }
}
