import Foundation
import Combine

@MainActor
protocol WeightGoalCoordinating: ObservableObject {
    var unitAbbreviation: String { get }
    var startWeightString: String { get set }
    var startWeightDate: Date { get set }
    var isFetchingStartWeight: Bool { get }
    var startWeightStatusMessage: String? { get }
    var startWeightErrorMessage: String? { get }
    var milestoneCount: Int { get set }
    var weightGoalString: String { get set }

    var canSaveStartWeight: Bool { get }

    func prepareStartWeightDefaults()
    func handleStartWeightDateChange(_ date: Date)
    func formatStartWeightInput(_ input: String)
    func saveStartWeight()
    func fetchStartWeight(for date: Date)
    func formatWeightGoalInput(_ input: String)
    func updateMilestoneCount(_ newValue: Int)
}

@MainActor
final class WeightGoalCoordinator: WeightGoalCoordinating {
    // MARK: - Published State

    @Published var startWeightString: String = ""
    @Published var startWeightDate: Date = Date()
    @Published private(set) var isFetchingStartWeight: Bool = false
    @Published private(set) var startWeightStatusMessage: String?
    @Published private(set) var startWeightErrorMessage: String?
    @Published var milestoneCount: Int = 10
    @Published var weightGoalString: String = ""

    // MARK: - Dependencies

    private let weightManager: WeightManager
    private let healthKitManager: HealthKitManagerProtocol

    // MARK: - Locale + Formatting

    private var activeLocale: Locale
    private var localeChangeObserver: NSObjectProtocol?
    private let measurementProvider: MeasurementSystemProviding
    private var measurementSystemCancellable: AnyCancellable?
    private lazy var startWeightFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.generatesDecimalNumbers = true
        return formatter
    }()
    private var currentStartWeightPounds: Double?
    private var currentStartWeightValue: Double?
    @Published private(set) var displayedUnitAbbreviation: String

    // MARK: - Public API

    var unitAbbreviation: String {
        displayedUnitAbbreviation
    }

    var canSaveStartWeight: Bool {
        guard !hasTrailingDecimalSeparator(),
              let value = parsedStartWeightValue() else {
            return false
        }
        return value > 0
    }

    // MARK: - Lifecycle

    init(weightManager: WeightManager,
         measurementProvider: MeasurementSystemProviding = MeasurementSystemProvider.shared,
         locale: Locale = .current,
         healthKitManager: HealthKitManagerProtocol) {
        self.weightManager = weightManager
        self.healthKitManager = healthKitManager
        self.measurementProvider = measurementProvider
        self.activeLocale = locale
        self.displayedUnitAbbreviation = weightManager.currentUnitAbbreviation

        configureStartWeightFormatter(with: locale)
        observeLocaleChanges()
        observeMeasurementSystemChanges()
        initializeStartWeight()
        synchronizeGoalWeightDisplay()
    }

    deinit {
        if let observer = localeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            localeChangeObserver = nil
        }
        measurementSystemCancellable?.cancel()
    }

    // MARK: - Locale Handling

    private func observeLocaleChanges() {
        localeChangeObserver = NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.handleLocaleDidChange()
            }
        }
    }

    private func observeMeasurementSystemChanges() {
        measurementSystemCancellable = measurementProvider.measurementSystemPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleMeasurementSystemDidChange()
            }
    }

    private func configureStartWeightFormatter(with locale: Locale) {
        startWeightFormatter.locale = locale
        let probeFormatter = NumberFormatter()
        probeFormatter.locale = locale
        if let decimalSeparator = probeFormatter.decimalSeparator {
            startWeightFormatter.decimalSeparator = decimalSeparator
        }
    }

    private func handleLocaleDidChange() {
        applyLocale(Locale.current)
    }

    private func handleMeasurementSystemDidChange() {
        applyLocale(measurementProvider.locale)
    }

    private func applyLocale(_ locale: Locale) {
        let previousFormatter = startWeightFormatter
        let existingValue = previousFormatter.number(from: startWeightString)?.doubleValue ?? currentStartWeightValue

        activeLocale = locale
        configureStartWeightFormatter(with: locale)

        var pounds = currentStartWeightPounds

        if pounds == nil, let override = weightManager.startWeightOverride {
            pounds = override
        }

        if pounds == nil, let value = existingValue {
            let previousUnit = displayedUnitAbbreviation == WeightUnit.kilograms.abbreviation ? WeightUnit.kilograms : .pounds
            let poundsValue: Double
            switch previousUnit {
            case .kilograms:
                poundsValue = value / 0.453592
            case .pounds:
                poundsValue = value
            }
            pounds = poundsValue
        }

        if let pounds {
            currentStartWeightPounds = pounds
            startWeightString = formatDisplayWeight(fromPounds: pounds)
        } else {
            startWeightString = ""
        }

        displayedUnitAbbreviation = weightManager.currentUnitAbbreviation
        synchronizeGoalWeightDisplay()
    }

    func refreshMeasurementDisplay() {
        applyLocale(measurementProvider.locale)
    }

    // MARK: - Start Weight Management

    func prepareStartWeightDefaults() {
        if startWeightString.isEmpty {
            handleStartWeightDateChange(startWeightDate)
        }
    }

    func handleStartWeightDateChange(_ date: Date) {
        startWeightDate = date
        fetchStartWeight(for: date)
    }

    func formatStartWeightInput(_ input: String) {
        configureStartWeightFormatter(with: activeLocale)
        let formatter = startWeightFormatter

        guard !input.isEmpty else {
            startWeightString = ""
            currentStartWeightValue = nil
            WeightTrackerMetrics.recordGoalEvent(.startWeightInputEmpty)
            return
        }

        let decimalSeparator = Character(formatter.decimalSeparator ?? ".")
        let groupingSeparator = formatter.groupingSeparator ?? ""
        var workingInput = input.replacingOccurrences(of: groupingSeparator, with: "")
        workingInput.removeAll(where: { $0.isWhitespace })

        var allowed = Set("0123456789")
        allowed.insert(decimalSeparator)

        var sanitized = workingInput.filter { allowed.contains($0) }

        if let firstSep = sanitized.firstIndex(of: decimalSeparator),
           let extraSep = sanitized[sanitized.index(after: firstSep)...].firstIndex(of: decimalSeparator) {
            sanitized.remove(at: extraSep)
        }

        if sanitized.isEmpty {
            startWeightString = sanitized
            currentStartWeightValue = nil
            WeightTrackerMetrics.recordGoalEvent(.startWeightInputInvalid)
            return
        }

        if sanitized.last == decimalSeparator {
            startWeightString = sanitized
            currentStartWeightValue = nil
            WeightTrackerMetrics.recordGoalEvent(.startWeightTrailingSeparator)
            return
        }

        guard let number = formatter.number(from: sanitized)?.doubleValue else {
            startWeightString = sanitized
            currentStartWeightValue = nil
            WeightTrackerMetrics.recordGoalEvent(.startWeightInputInvalid)
            return
        }

        let clamped = min(number, 999.9)
        let pounds = weightManager.convertToInternalUnit(clamped)
        currentStartWeightPounds = pounds
        startWeightString = formatDisplayWeight(fromPounds: pounds)
    }

    func fetchStartWeight(for date: Date) {
        startWeightErrorMessage = nil
        isFetchingStartWeight = true
        startWeightStatusMessage = "Fetching weight data…"

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            isFetchingStartWeight = false
            startWeightStatusMessage = nil
            startWeightErrorMessage = "Unable to calculate date range."
            return
        }

        if healthKitManager.isWeightAuthorized() {
            healthKitManager.fetchWeightData(startDate: startOfDay, endDate: endOfDay, resetAnchor: true) { [weak self] entries in
                Task { @MainActor in
                    self?.applyStartWeightData(hkEntries: entries, date: date)
                }
            }
        } else {
            applyStartWeightData(hkEntries: [], date: date)
        }
    }

    func saveStartWeight() {
        startWeightErrorMessage = nil
        configureStartWeightFormatter(with: activeLocale)
        let formatter = startWeightFormatter

        let parsedValue = formatter.number(from: startWeightString)?.doubleValue ?? currentStartWeightValue

        guard let number = parsedValue, number > 0 else {
            startWeightErrorMessage = "Enter a valid start weight."
            WeightTrackerMetrics.recordGoalEvent(.startWeightRejected, metadata: ["reason": "invalid_input"])
            return
        }

        currentStartWeightValue = number
        startWeightString = formattedStartWeightDisplay(from: number)
        weightManager.setStartWeightOverride(number, date: startWeightDate)
        startWeightStatusMessage = "Start weight saved."
        WeightTrackerMetrics.recordGoalEvent(.startWeightSaved, metadata: ["source": "manual"])
    }

    func formatWeightGoalInput(_ input: String) {
        var formatted = input
        var truncateReason: String?

        formatted = formatted.filter { $0.isNumber || $0 == "." }

        let components = formatted.components(separatedBy: ".")
        if components.count > 2 {
            formatted = components[0] + "." + components[1...].joined()
            truncateReason = "multiple_decimals"
        }

        if let dotIndex = formatted.firstIndex(of: ".") {
            let afterDot = formatted.suffix(from: formatted.index(after: dotIndex))
            if afterDot.count > 1 {
                formatted = String(formatted.prefix(upTo: formatted.index(dotIndex, offsetBy: 2)))
                truncateReason = truncateReason ?? "fraction_length"
            }
        }

        let hasDecimal = formatted.contains(".")
        let valueBeforeLimiting = Double(formatted) ?? 0
        if hasDecimal && valueBeforeLimiting > 999.9 {
            formatted = "999.9"
        } else {
            if let dotIndex = formatted.firstIndex(of: ".") {
                let beforeDot = formatted.prefix(upTo: dotIndex)
                if beforeDot.count > 3 {
                    formatted = String(beforeDot.prefix(3)) + String(formatted.suffix(from: dotIndex))
                    truncateReason = truncateReason ?? "integer_length"
                }
            } else {
                if formatted.count > 3 {
                    formatted = String(formatted.prefix(3))
                    truncateReason = truncateReason ?? "integer_length"
                }
            }
        }

        weightGoalString = formatted
        if let reason = truncateReason {
            WeightTrackerMetrics.recordGoalEvent(.goalWeightInputTruncated, metadata: ["reason": reason])
        }
    }

    func updateMilestoneCount(_ newValue: Int) {
        let sanitized = max(0, min(10, newValue))
        milestoneCount = sanitized
        weightManager.setMilestoneCount(sanitized)
        WeightTrackerMetrics.recordGoalEvent(.milestoneUpdated, metadata: ["count": "\(sanitized)"])
    }

    // MARK: - Private Helpers

    private func initializeStartWeight() {
        configureStartWeightFormatter(with: activeLocale)

        if let override = weightManager.startWeightOverride {
            startWeightString = formatDisplayWeight(fromPounds: override)
            startWeightDate = weightManager.startWeightDate ?? Date()
            startWeightStatusMessage = "Using custom start weight."
            currentStartWeightValue = weightManager.convertWeightToDisplayUnit(override)
        } else if let earliest = weightManager.weightEntries.last {
            startWeightString = formatDisplayWeight(fromPounds: earliest.weight)
            startWeightDate = earliest.date
            startWeightStatusMessage = "Baseline from earliest entry."
            currentStartWeightValue = weightManager.convertWeightToDisplayUnit(earliest.weight)
        } else {
            startWeightDate = Date()
            startWeightString = ""
            startWeightStatusMessage = nil
            currentStartWeightValue = nil
        }

        milestoneCount = weightManager.milestoneCount
    }

    func synchronizeGoalWeightDisplay() {
        let storedGoal = weightManager.goalWeight
        if storedGoal > 0 {
            weightGoalString = weightManager.formattedDisplayWeight(storedGoal)
        } else {
            weightGoalString = ""
        }
    }

    private func formatDisplayWeight(fromPounds pounds: Double) -> String {
        configureStartWeightFormatter(with: activeLocale)
        let displayValue = weightManager.convertWeightToDisplayUnit(pounds)
        return formattedStartWeightDisplay(from: displayValue)
    }

    private func formattedStartWeightDisplay(from displayValue: Double) -> String {
        startWeightFormatter.maximumFractionDigits = 1
        startWeightFormatter.minimumFractionDigits = displayValue.truncatingRemainder(dividingBy: 1).isZero ? 0 : 1
        return startWeightFormatter.string(from: NSNumber(value: displayValue)) ?? String(format: "%.1f", displayValue)
    }

    private func parsedStartWeightValue() -> Double? {
        configureStartWeightFormatter(with: activeLocale)
        if let value = startWeightFormatter.number(from: startWeightString)?.doubleValue {
            return value
        }
        return currentStartWeightValue
    }

    private func hasTrailingDecimalSeparator() -> Bool {
        configureStartWeightFormatter(with: activeLocale)
        guard let separator = startWeightFormatter.decimalSeparator else {
            return false
        }
        return startWeightString.hasSuffix(separator)
    }

    private func applyStartWeightData(hkEntries: [WeightEntry], date: Date) {
        let calendar = Calendar.current
        let localEntries = weightManager.weightEntries.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let combinedWeights = (hkEntries + localEntries).map { $0.weight }

        isFetchingStartWeight = false

        guard !combinedWeights.isEmpty else {
            startWeightStatusMessage = "No weight logged for this date. Enter a value manually."
            startWeightString = ""
            WeightTrackerMetrics.recordGoalEvent(.startWeightRejected, metadata: ["reason": "no_data"])
            return
        }

        let average = combinedWeights.reduce(0, +) / Double(combinedWeights.count)
        currentStartWeightPounds = average
        startWeightString = formatDisplayWeight(fromPounds: average)
        startWeightStatusMessage = "Auto-filled from \(combinedWeights.count) data source\(combinedWeights.count == 1 ? "" : "s")."
        WeightTrackerMetrics.recordGoalEvent(
            .startWeightAutofill,
            metadata: [
                "source_count": "\(combinedWeights.count)",
                "has_hk": hkEntries.isEmpty ? "false" : "true",
                "has_manual": localEntries.isEmpty ? "false" : "true"
            ]
        )
    }
}
