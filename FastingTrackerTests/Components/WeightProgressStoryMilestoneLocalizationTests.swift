import XCTest
@testable import FastLIFe

final class WeightProgressStoryMilestoneLocalizationTests: XCTestCase {

    func testUnitAbbreviationImperialLocale() {
        let locale = Locale(identifier: "en_US")
        XCTAssertEqual(
            WeightProgressStoryMilestoneLocalization.unitAbbreviation(for: locale),
            NSLocalizedString("progress_story_unit_lbs", comment: "")
        )
    }

    func testUnitAbbreviationMetricLocale() {
        let locale = Locale(identifier: "fr_FR")
        XCTAssertEqual(
            WeightProgressStoryMilestoneLocalization.unitAbbreviation(for: locale),
            NSLocalizedString("progress_story_unit_kg", comment: "")
        )
    }

    func testFormattedWeightRespectsLocale() {
        let imperial = WeightProgressStoryMilestoneLocalization.formattedWeight(150, locale: Locale(identifier: "en_US"))
        let metric = WeightProgressStoryMilestoneLocalization.formattedWeight(150, locale: Locale(identifier: "fr_FR"))
        XCTAssertNotEqual(imperial, metric)
    }

    func testAccessibilityLabelWithValue() {
        let label = WeightProgressStoryMilestoneLocalization.accessibilityLabel(
            tag: "LOST",
            formattedValue: "5.0",
            unitAbbreviation: "lbs",
            periodLabel: "7 DAYS"
        )
        XCTAssertTrue(label.contains("LOST"))
        XCTAssertTrue(label.contains("5.0"))
        XCTAssertTrue(label.contains("lbs"))
    }

    func testAccessibilityLabelNoData() {
        let label = WeightProgressStoryMilestoneLocalization.accessibilityLabel(
            tag: "NO DATA",
            formattedValue: nil,
            unitAbbreviation: "lbs",
            periodLabel: "7 DAYS"
        )
        XCTAssertTrue(label.contains("NO DATA"))
    }
}
