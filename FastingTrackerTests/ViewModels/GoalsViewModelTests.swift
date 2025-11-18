//
//  GoalsViewModelTests.swift
//  FastingTrackerTests
//
//  Created by Claude Code
//  Task 1B: Comprehensive Testing - ViewModel Test Suite
//  Reference: Industry TDD patterns (Google/Facebook test methodology)
//

import XCTest
@testable import FastLIFe

@MainActor
final class GoalsViewModelTests: XCTestCase {

    var viewModel: GoalsViewModel!

    override func setUp() {
        super.setUp()
        viewModel = GoalsViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_setsEmptyWeightGoalString() {
        // Given - fresh ViewModel

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "",
                      "weightGoalString should start as empty string")
    }

    // MARK: - Formatting Tests - Valid Inputs

    func test_formatWeightGoalInput_validInteger() {
        // Given
        let input = "180"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "180",
                      "Valid integer should be accepted as-is")
    }

    func test_formatWeightGoalInput_validDecimal() {
        // Given
        let input = "175.5"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "175.5",
                      "Valid decimal should be accepted")
    }

    func test_formatWeightGoalInput_singleDigit() {
        // Given
        let input = "5"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "5",
                      "Single digit should be accepted")
    }

    // MARK: - Decimal Handling Tests

    func test_formatWeightGoalInput_limitsToOneDecimalPlace() {
        // Given - input with 2 decimal places
        let input = "175.55"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "175.5",
                      "Should limit to 1 decimal place (truncate, not round)")
    }

    func test_formatWeightGoalInput_limitsToOneDecimalPlace_multipleDigits() {
        // Given - input with many decimal places
        let input = "180.999"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "180.9",
                      "Should limit to 1 decimal place")
    }

    func test_formatWeightGoalInput_multipleDecimalPoints_keepsFirst() {
        // Given - input with multiple decimal points
        let input = "175.5.5"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "175.5",
                      "Should keep first decimal point only, limit to 1 decimal place")
    }

    func test_formatWeightGoalInput_decimalPointOnly() {
        // Given - just a decimal point
        let input = "."

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, ".",
                      "Decimal point alone should be allowed (user is starting to type)")
    }

    func test_formatWeightGoalInput_integerThenDecimalPoint() {
        // Given - integer followed by decimal (user typing)
        let input = "175."

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "175.",
                      "Integer + decimal point should be allowed (user typing)")
    }

    // MARK: - Max Value Tests

    func test_formatWeightGoalInput_maxValue_exactly() {
        // Given - exactly 999.9
        let input = "999.9"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "999.9",
                      "Max value 999.9 should be accepted")
    }

    func test_formatWeightGoalInput_exceedsMaxValue_withDecimal() {
        // Given - exceeds max value with decimal
        let input = "1000.5"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "999.9",
                      "Values exceeding 999.9 should be capped to 999.9")
    }

    func test_formatWeightGoalInput_exceedsMaxValue_largeDecimal() {
        // Given - very large value with decimal
        let input = "1500.0"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "999.9",
                      "Large values with decimal should be capped to 999.9")
    }

    // MARK: - Digit Limiting Tests (Without Decimal)

    func test_formatWeightGoalInput_limitsToThreeDigits_noDecimal() {
        // Given - more than 3 digits without decimal
        let input = "12345"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "123",
                      "Should limit to 3 digits when no decimal point")
    }

    func test_formatWeightGoalInput_limitsIntegerPartToThreeDigits() {
        // Given - more than 3 digits before decimal
        let input = "12345.5"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "123.5",
                      "Integer part should be limited to 3 digits")
    }

    // MARK: - Non-Numeric Character Filtering Tests

    func test_formatWeightGoalInput_filtersLetters() {
        // Given - input with letters
        let input = "175abc"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "175",
                      "Should filter out letters")
    }

    func test_formatWeightGoalInput_filtersSymbols() {
        // Given - input with symbols
        let input = "180!@#$%"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "180",
                      "Should filter out symbols (except decimal point)")
    }

    func test_formatWeightGoalInput_filtersMixedNonNumeric() {
        // Given - mixed numeric and non-numeric
        let input = "1a7b5.c5d"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "175.5",
                      "Should filter out all non-numeric except decimal")
    }

    // MARK: - Edge Cases

    func test_formatWeightGoalInput_emptyString() {
        // Given - empty string
        let input = ""

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "",
                      "Empty string should remain empty")
    }

    func test_formatWeightGoalInput_onlyNonNumericCharacters() {
        // Given - only non-numeric characters
        let input = "abc!@#"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "",
                      "Only non-numeric characters should result in empty string")
    }

    func test_formatWeightGoalInput_multipleDecimalPoints_complex() {
        // Given - complex input with multiple decimals
        let input = "1.2.3.4.5"

        // When
        viewModel.formatWeightGoalInput(input)

        // Then
        XCTAssertEqual(viewModel.weightGoalString, "1.2",
                      "Should keep first decimal, limit to 1 decimal place, combine remaining digits")
    }

    // MARK: - Sequential Input Tests (Simulating User Typing)

    func test_formatWeightGoalInput_sequentialTyping() {
        // Simulate user typing "175.5" character by character

        // Type "1"
        viewModel.formatWeightGoalInput("1")
        XCTAssertEqual(viewModel.weightGoalString, "1")

        // Type "17"
        viewModel.formatWeightGoalInput("17")
        XCTAssertEqual(viewModel.weightGoalString, "17")

        // Type "175"
        viewModel.formatWeightGoalInput("175")
        XCTAssertEqual(viewModel.weightGoalString, "175")

        // Type "175."
        viewModel.formatWeightGoalInput("175.")
        XCTAssertEqual(viewModel.weightGoalString, "175.")

        // Type "175.5"
        viewModel.formatWeightGoalInput("175.5")
        XCTAssertEqual(viewModel.weightGoalString, "175.5")
    }

    func test_formatWeightGoalInput_sequentialTyping_attemptTooManyDecimalPlaces() {
        // Simulate user attempting to type "175.55"

        viewModel.formatWeightGoalInput("175.5")
        XCTAssertEqual(viewModel.weightGoalString, "175.5")

        // Attempt to type another 5 (should be limited)
        viewModel.formatWeightGoalInput("175.55")
        XCTAssertEqual(viewModel.weightGoalString, "175.5",
                      "Should prevent typing second decimal place")
    }
}
