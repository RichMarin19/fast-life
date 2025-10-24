# LifeGPT Intelligence Layer - Implementation Spec
**Phase:** Phase 2 - Smart Query Engine
**Date:** 2025-10-24
**Status:** Planning → Ready to Build
**Timeline:** 3 hours (Phase 1 MVP)

---

## 🎯 **Objective**
Transform LifeGPT from basic chat UI into intelligent health data analyst that answers complex queries using natural language.

**Example Queries:**
- "What's the least I ever weighed and when was it?"
- "What's the most weight I lost in a calendar month?"
- "What's the most I gained in a 30 day period?"

---

## 🏗️ **Architecture (MVVM + Industry Standards)**

### **Three-Layer Intelligence System**

```
User Query → [1] QueryClassifier → [2] HealthDataAnalyzer → [3] ResponseGenerator → ChatMessage
```

**Industry References:**
- Query Classification: Google Dialogflow, Amazon Alexa, Siri Shortcuts
- Data Analysis: Apple HealthKit Statistics, Google Fit Aggregated Data API
- Response Generation: Duolingo motivational messaging, MyFitnessPal celebrations

---

## 📁 **File Structure**

```
FastingTracker/
├── Core/
│   ├── Services/
│   │   ├── QueryClassifier.swift          [NEW - Layer 1]
│   │   ├── HealthDataAnalyzer.swift       [NEW - Protocol]
│   │   ├── HealthDataAnalysisService.swift [NEW - Layer 2]
│   │   ├── ResponseGenerator.swift        [NEW - Layer 3]
│   │   └── UnifiedHealthDataService.swift [EXISTING - Data source]
│   ├── ViewModels/
│   │   └── LifeGPTViewModel.swift         [EXTEND - Wire layers]
│   └── Models/
│       ├── QueryIntent.swift              [NEW - Intent enum]
│       ├── AnalysisResult.swift           [NEW - Data result]
│       └── ResponseContext.swift          [NEW - Response context]
```

---

## 🎯 **Layer 1: Query Classifier**

**File:** `FastingTracker/Core/Services/QueryClassifier.swift`

**Purpose:** Parse user input using pattern matching (NO AI/ML - 100% offline, privacy-first)

### **Protocol Definition**

```swift
protocol QueryClassifying {
    func classify(_ query: String) -> QueryIntent
}
```

### **Query Intent Model**

```swift
// File: FastingTracker/Core/Models/QueryIntent.swift

enum QueryIntent {
    case weightStats(StatType, TimeRange?)
    case fastingStats(StatType, TimeRange?)
    case weightTrend(TimeRange)
    case comparison(HealthMetric, TimeRange, TimeRange)
    case summary(TimeRange)
    case unknown
}

enum StatType {
    case minimum, maximum, average, total, count, change
}

enum TimeRange {
    case today, yesterday, thisWeek, lastWeek, thisMonth, lastMonth
    case last30Days, last90Days, allTime
    case custom(Date, Date)
}

enum HealthMetric {
    case weight, fasting, sleep, hydration, mood
}
```

### **Pattern Matching Strategy**

**Phase 1 Patterns (20 queries minimum):**

| Pattern | Intent | Example |
|---------|--------|---------|
| "lowest\|least.*weigh" | weightStats(.minimum, .allTime) | "What's my lowest weight?" |
| "highest\|most.*weigh" | weightStats(.maximum, .allTime) | "What's my highest weight?" |
| "average.*weight.*month" | weightStats(.average, .lastMonth) | "Average weight last month?" |
| "most.*lost.*month" | weightStats(.change, .lastMonth) | "Most weight lost in a month?" |
| "most.*gained.*30.*day" | weightStats(.change, .last30Days) | "Most gained in 30 days?" |
| "how many.*fast.*week" | fastingStats(.count, .thisWeek) | "How many fasts this week?" |
| "longest.*fast" | fastingStats(.maximum, .allTime) | "What's my longest fast?" |
| "weight.*trend.*month" | weightTrend(.thisMonth) | "Weight trend this month?" |

**Implementation Approach:**
1. Lowercase and normalize query
2. Extract time range keywords (today, week, month, 30 days, etc.)
3. Match stat type keywords (lowest, highest, average, most, etc.)
4. Match metric keywords (weight, fast, etc.)
5. Return structured QueryIntent

### **Design Tokens & Single Source of Truth**

```swift
// Pattern dictionary as single source of truth
struct QueryPatterns {
    // Weight patterns
    static let minimumWeight = [
        "lowest", "least", "minimum", "min", "smallest"
    ]
    static let maximumWeight = [
        "highest", "most", "maximum", "max", "largest", "heaviest"
    ]
    static let averageWeight = [
        "average", "avg", "mean", "typical"
    ]

    // Time range patterns
    static let today = ["today", "current"]
    static let thisWeek = ["this week", "week"]
    static let lastMonth = ["last month", "previous month"]
    static let thirtyDays = ["30 day", "30-day", "thirty day"]

    // Metric patterns
    static let weight = ["weight", "weigh", "lb", "lbs", "kg", "pound"]
    static let fasting = ["fast", "fasting", "fasted"]
}
```

**Automation Opportunity:** Generate test cases from pattern dictionary

---

## 🎯 **Layer 2: Health Data Analyzer**

**File:** `FastingTracker/Core/Services/HealthDataAnalyzer.swift` (Protocol)
**File:** `FastingTracker/Core/Services/HealthDataAnalysisService.swift` (Implementation)

**Purpose:** Execute analytics against unified health data

### **Protocol Definition**

```swift
protocol HealthDataAnalyzer {
    // Weight analytics
    func findMinimumWeight(in range: TimeRange?) async -> (weight: Double, date: Date)?
    func findMaximumWeight(in range: TimeRange?) async -> (weight: Double, date: Date)?
    func calculateAverageWeight(in range: TimeRange) async -> Double?
    func calculateWeightChange(in range: TimeRange) async -> Double?
    func findLargestWeightLoss(windowDays: Int) async -> (loss: Double, startDate: Date, endDate: Date)?
    func findLargestWeightGain(windowDays: Int) async -> (gain: Double, startDate: Date, endDate: Date)?

    // Fasting analytics
    func countFasts(in range: TimeRange, minimumHours: Int?) async -> Int
    func findLongestFast() async -> (duration: TimeInterval, date: Date)?
    func calculateFastingStreak() async -> Int

    // Trend analytics
    func calculateWeightTrend(in range: TimeRange) async -> TrendAnalysis
}

struct TrendAnalysis {
    let startWeight: Double
    let endWeight: Double
    let change: Double
    let percentageChange: Double
    let direction: TrendDirection
    let dataPoints: Int
}

enum TrendDirection {
    case improving, stable, regressing
}
```

### **Implementation Strategy**

**Industry Pattern:** Apple HealthKit's `HKStatisticsQuery` approach

```swift
class HealthDataAnalysisService: HealthDataAnalyzer {
    private let dataService: HealthDataAggregator

    // MARK: - Weight Analytics

    func findMinimumWeight(in range: TimeRange?) async -> (weight: Double, date: Date)? {
        let weightData = await fetchWeightData(for: range)
        guard let minEntry = weightData.min(by: { $0.weight < $1.weight }) else {
            return nil
        }
        return (minEntry.weight, minEntry.date)
    }

    func findLargestWeightLoss(windowDays: Int) async -> (loss: Double, startDate: Date, endDate: Date)? {
        let allWeightData = await dataService.fetchAllWeightData()
        guard allWeightData.count >= windowDays else { return nil }

        // Sliding window algorithm
        var maxLoss = 0.0
        var bestWindow: (Date, Date)?

        for i in 0..<(allWeightData.count - windowDays) {
            let windowStart = allWeightData[i]
            let windowEnd = allWeightData[i + windowDays]
            let loss = windowStart.weight - windowEnd.weight

            if loss > maxLoss {
                maxLoss = loss
                bestWindow = (windowStart.date, windowEnd.date)
            }
        }

        guard let window = bestWindow else { return nil }
        return (maxLoss, window.0, window.1)
    }

    // MARK: - Helper Methods

    private func fetchWeightData(for range: TimeRange?) async -> [WeightEntry] {
        guard let range = range else {
            return await dataService.fetchAllWeightData()
        }

        let (startDate, endDate) = range.dateRange()
        return await dataService.fetchWeightData(from: startDate, to: endDate)
    }
}

// TimeRange extension for date conversion
extension TimeRange {
    func dateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now)
        case .thisWeek:
            let start = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date!
            return (start, now)
        case .lastMonth:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            return (start, now)
        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -30, to: now)!
            return (start, now)
        case .allTime:
            return (Date.distantPast, now)
        case .custom(let start, let end):
            return (start, end)
        // ... other cases
        }
    }
}
```

### **Optimization: Calculation Caching**

```swift
// Add to HealthDataAnalysisService
private var cachedStats: CachedStats?

struct CachedStats {
    let minWeight: (Double, Date)?
    let maxWeight: (Double, Date)?
    let averageWeight: Double?
    let calculatedAt: Date

    var isStale: Bool {
        Date().timeIntervalSince(calculatedAt) > 3600 // 1 hour
    }
}

func invalidateCache() {
    cachedStats = nil
}
```

**Automation:** Invalidate cache when new weight data is added

---

## 🎯 **Layer 3: Response Generator**

**File:** `FastingTracker/Core/Services/ResponseGenerator.swift`

**Purpose:** Convert analysis results into emotion-aware natural language responses

### **Protocol Definition**

```swift
protocol ResponseGenerating {
    func generateResponse(
        for intent: QueryIntent,
        result: AnalysisResult,
        emotion: EmotionState
    ) -> String
}

struct AnalysisResult {
    // Weight results
    var minWeight: (value: Double, date: Date)?
    var maxWeight: (value: Double, date: Date)?
    var averageWeight: Double?
    var weightChange: Double?
    var largestLoss: (loss: Double, startDate: Date, endDate: Date)?
    var largestGain: (gain: Double, startDate: Date, endDate: Date)?

    // Fasting results
    var fastCount: Int?
    var longestFast: (duration: TimeInterval, date: Date)?
    var fastingStreak: Int?

    // Trend results
    var trendAnalysis: TrendAnalysis?
}
```

### **Response Templates (Design Tokens)**

**Industry Pattern:** Duolingo's motivational messaging system

```swift
struct ResponseTemplates {
    // MARK: - Weight Stats Templates

    static let minimumWeight: [EmotionState: String] = [
        .energized: "Your lowest recorded weight was {weight} on {date}. You've made incredible progress! 🎯",
        .stable: "Your lowest recorded weight was {weight} on {date}. That's your benchmark to beat! 💪",
        .stressed: "Your lowest recorded weight was {weight} on {date}. Remember how far you've come. You can get back there! 🌟",
        .tired: "Your lowest recorded weight was {weight} on {date}. Take it one day at a time. 🌙",
        .offtrack: "Your lowest recorded weight was {weight} on {date}. Small steps will get you back on track! 🚶"
    ]

    static let maximumWeight: [EmotionState: String] = [
        .energized: "Your highest recorded weight was {weight} on {date}. Look how far you've come since then! 🚀",
        .stable: "Your highest recorded weight was {weight} on {date}. You've made progress from there! 📊",
        .stressed: "Your highest recorded weight was {weight} on {date}. Progress isn't always linear, but you're moving forward. 💫",
        .tired: "Your highest recorded weight was {weight} on {date}. Be proud of any progress you've made. 🌟",
        .offtrack: "Your highest recorded weight was {weight} on {date}. Every journey starts somewhere! 🌱"
    ]

    static let largestLoss: [EmotionState: String] = [
        .energized: "Your biggest weight loss was {loss} between {startDate} and {endDate}. You crushed it! 🏆",
        .stable: "Your biggest weight loss was {loss} over {days} days ({startDate} - {endDate}). Impressive consistency! 📈",
        .stressed: "Your biggest weight loss was {loss} between {startDate} and {endDate}. You've done it before, you can do it again! 💪",
        .tired: "Your biggest weight loss was {loss} over {days} days. Take inspiration from that success! ✨",
        .offtrack: "Your biggest weight loss was {loss} between {startDate} and {endDate}. That same strength is still in you! 🔥"
    ]

    // MARK: - Fallback Templates

    static let noData = "I don't have enough data yet to answer that. Keep tracking your progress! 📊"
    static let unknownQuery = "I'm not sure how to help with that yet. Try asking about your weight trends, fasting stats, or progress milestones! 💬"
}
```

### **Implementation**

```swift
struct ResponseGenerator: ResponseGenerating {
    func generateResponse(
        for intent: QueryIntent,
        result: AnalysisResult,
        emotion: EmotionState
    ) -> String {
        switch intent {
        case .weightStats(.minimum, _):
            return formatMinWeightResponse(result, emotion: emotion)
        case .weightStats(.maximum, _):
            return formatMaxWeightResponse(result, emotion: emotion)
        case .weightStats(.change, let range):
            return formatWeightChangeResponse(result, range: range, emotion: emotion)
        case .unknown:
            return ResponseTemplates.unknownQuery
        // ... other cases
        }
    }

    // MARK: - Formatters

    private func formatMinWeightResponse(_ result: AnalysisResult, emotion: EmotionState) -> String {
        guard let minWeight = result.minWeight else {
            return ResponseTemplates.noData
        }

        let template = ResponseTemplates.minimumWeight[emotion] ?? ResponseTemplates.minimumWeight[.stable]!

        return template
            .replacingOccurrences(of: "{weight}", with: formatWeight(minWeight.value))
            .replacingOccurrences(of: "{date}", with: formatDate(minWeight.date))
    }

    private func formatWeight(_ weight: Double) -> String {
        String(format: "%.1f lbs", weight)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatDateRange(_ startDate: Date, _ endDate: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return "\(days) days"
    }
}
```

**Automation Opportunity:** A/B test template variants to optimize user engagement

---

## 🔧 **ViewModel Integration**

**File:** `FastingTracker/Core/ViewModels/LifeGPTViewModel.swift` (EXTEND)

### **New Dependencies**

```swift
// Add to LifeGPTViewModel
private let queryClassifier: QueryClassifying
private let dataAnalyzer: HealthDataAnalyzer
private let responseGenerator: ResponseGenerating

init(
    dataService: HealthDataAggregator,
    queryClassifier: QueryClassifying = QueryClassifier(),
    dataAnalyzer: HealthDataAnalyzer = HealthDataAnalysisService(dataService: dataService),
    responseGenerator: ResponseGenerating = ResponseGenerator()
) {
    self.dataService = dataService
    self.queryClassifier = queryClassifier
    self.dataAnalyzer = dataAnalyzer
    self.responseGenerator = responseGenerator
}
```

### **Extended sendQuery Method**

```swift
func sendQuery(_ query: String) {
    // Don't send empty messages
    guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    // Add user message
    let userMessage = ChatMessage(content: query, isFromUser: true)
    messages.append(userMessage)
    inputText = ""

    // Set processing state
    isProcessing = true

    Task {
        // 1. Classify intent
        let intent = queryClassifier.classify(query)

        // 2. Execute analysis
        let result = await executeQuery(for: intent)

        // 3. Determine emotion from result
        let emotion = determineEmotion(from: result, intent: intent)

        // 4. Generate response
        let responseText = responseGenerator.generateResponse(
            for: intent,
            result: result,
            emotion: emotion
        )

        // 5. Add assistant message
        await MainActor.run {
            let assistantMessage = ChatMessage(
                content: responseText,
                isFromUser: false,
                emotion: emotion
            )
            messages.append(assistantMessage)
            isProcessing = false
        }
    }
}

// MARK: - Query Execution

private func executeQuery(for intent: QueryIntent) async -> AnalysisResult {
    var result = AnalysisResult()

    switch intent {
    case .weightStats(.minimum, let range):
        result.minWeight = await dataAnalyzer.findMinimumWeight(in: range)

    case .weightStats(.maximum, let range):
        result.maxWeight = await dataAnalyzer.findMaximumWeight(in: range)

    case .weightStats(.average, let range):
        if let range = range {
            result.averageWeight = await dataAnalyzer.calculateAverageWeight(in: range)
        }

    case .weightStats(.change, let range):
        if range == .lastMonth {
            result.largestLoss = await dataAnalyzer.findLargestWeightLoss(windowDays: 30)
        } else if range == .last30Days {
            result.largestGain = await dataAnalyzer.findLargestWeightGain(windowDays: 30)
        }

    case .fastingStats(.count, let range):
        if let range = range {
            result.fastCount = await dataAnalyzer.countFasts(in: range, minimumHours: nil)
        }

    case .fastingStats(.maximum, _):
        result.longestFast = await dataAnalyzer.findLongestFast()

    case .unknown:
        break

    // ... other cases
    }

    return result
}

// MARK: - Emotion Detection

private func determineEmotion(from result: AnalysisResult, intent: QueryIntent) -> EmotionState {
    // Use existing EmotionState detection logic
    // Enhanced with result context

    // Example: If asking about minimum weight and current weight is close to it
    if case .weightStats(.minimum, _) = intent,
       let minWeight = result.minWeight?.value {
        // Check current weight vs minimum
        // Return appropriate emotion
    }

    // Default to stable for data queries
    return .stable
}
```

---

## 📊 **Phase 1 Deliverables (3 Hours)**

### **Hour 1: Layer 1 - Query Classifier**
- ✅ Create `QueryIntent.swift` model
- ✅ Create `QueryClassifier.swift` with 20 patterns
- ✅ Write unit tests for classification
- ✅ Test with 10 example queries

### **Hour 2: Layer 2 - Health Data Analyzer**
- ✅ Create `HealthDataAnalyzer.swift` protocol
- ✅ Create `HealthDataAnalysisService.swift` implementation
- ✅ Implement 6 core analytics methods:
  - `findMinimumWeight()`
  - `findMaximumWeight()`
  - `calculateAverageWeight()`
  - `findLargestWeightLoss()`
  - `findLargestWeightGain()`
  - `countFasts()`
- ✅ Write unit tests for calculations

### **Hour 3: Layer 3 - Response Generator + Integration**
- ✅ Create `ResponseGenerator.swift` with emotion-aware templates
- ✅ Create `AnalysisResult.swift` model
- ✅ Extend `LifeGPTViewModel` with new layers
- ✅ End-to-end testing with 10 queries
- ✅ Device testing and UI verification

---

## 🚀 **Testing Strategy**

### **Unit Tests (Required)**

```swift
// QueryClassifierTests.swift
func testMinimumWeightQuery() {
    let classifier = QueryClassifier()
    let intent = classifier.classify("What's my lowest weight?")

    guard case .weightStats(.minimum, .allTime) = intent else {
        XCTFail("Expected minimum weight query")
        return
    }
}

// HealthDataAnalysisServiceTests.swift
func testFindMinimumWeight() async {
    let mockData = createMockWeightData()
    let analyzer = HealthDataAnalysisService(dataService: mockData)

    let result = await analyzer.findMinimumWeight(in: nil)

    XCTAssertEqual(result?.weight, 175.0)
}

// ResponseGeneratorTests.swift
func testMinimumWeightResponse() {
    let generator = ResponseGenerator()
    let result = AnalysisResult(minWeight: (175.0, Date()))

    let response = generator.generateResponse(
        for: .weightStats(.minimum, nil),
        result: result,
        emotion: .energized
    )

    XCTAssertTrue(response.contains("175.0"))
    XCTAssertTrue(response.contains("incredible progress"))
}
```

### **Integration Testing**

```swift
// LifeGPTViewModelTests.swift
func testEndToEndQuery() async {
    let viewModel = createTestViewModel()

    viewModel.sendQuery("What's my lowest weight?")

    // Wait for processing
    try? await Task.sleep(nanoseconds: 1_000_000_000)

    XCTAssertEqual(viewModel.messages.count, 2) // User + assistant
    XCTAssertTrue(viewModel.messages.last?.content.contains("lowest") ?? false)
}
```

---

## 🎯 **Success Criteria**

### **Phase 1 MVP**
- ✅ 20+ query patterns recognized
- ✅ 6+ analytics methods implemented
- ✅ Emotion-aware responses for all query types
- ✅ Zero build errors/warnings
- ✅ 100% unit test coverage for new code
- ✅ End-to-end device testing successful

### **Quality Metrics**
- Query recognition rate: 85%+ (target)
- Response accuracy: 100% (required)
- Response time: <500ms (target)
- Code coverage: 90%+ (target)

---

## ⚠️ **Known Pitfalls & Mitigation**

### **Pitfall 1: Ambiguous Queries**
**Example:** "How much weight did I lose?"
**Problem:** Timeframe unclear (this week? this month? all time?)
**Solution:** Default to most recent completed period (last 30 days) and clarify in response

### **Pitfall 2: Insufficient Data**
**Example:** User asks about "average weight last month" but only has 2 data points
**Problem:** Statistical meaninglessness
**Solution:** Require minimum data points (5+) and provide helpful message

### **Pitfall 3: Date Parsing Complexity**
**Example:** "3 weeks ago" or "since January"
**Problem:** Complex natural language date parsing
**Solution:** Phase 1 uses predefined time ranges only (today, this week, last month, etc.)

### **Pitfall 4: Unit Preferences**
**Example:** User asks "What's my lowest weight?" but uses kg, response shows lbs
**Problem:** Unit mismatch
**Solution:** Detect user's preferred unit from first weight entry, store as preference

---

## 🔄 **Automation Opportunities**

### **1. Pattern Generation from Logs**
```swift
struct QueryLogger {
    func logUnrecognizedQuery(_ query: String) {
        // Store in UserDefaults or CloudKit
        // Review monthly to expand pattern library
    }
}
```

### **2. Response A/B Testing**
```swift
struct ResponseVariantTracker {
    func trackResponse(
        variant: String,
        userReaction: Reaction // thumbs up/down
    ) {
        // Track which response templates get best engagement
        // Auto-select winning variants
    }
}
```

### **3. Calculation Caching**
```swift
// Auto-invalidate cache on data changes
extension UnifiedHealthDataService {
    func addWeightEntry(_ entry: WeightEntry) {
        // ... existing code ...
        NotificationCenter.default.post(name: .healthDataChanged, object: nil)
    }
}

// Listen in HealthDataAnalysisService
init() {
    NotificationCenter.default.addObserver(
        forName: .healthDataChanged,
        using: { [weak self] _ in
            self?.invalidateCache()
        }
    )
}
```

### **4. Unit Test Generation**
```swift
// Generate test cases from pattern dictionary
struct TestGenerator {
    static func generateClassifierTests() -> [String] {
        var tests: [String] = []

        for pattern in QueryPatterns.minimumWeight {
            tests.append("What's my \(pattern) weight?")
        }

        return tests
    }
}
```

---

## 📚 **Reference Documentation**

### **Industry Standards**
- **Apple HealthKit Statistics**: [Documentation](https://developer.apple.com/documentation/healthkit/hkstatisticsquery)
- **Google Dialogflow Intent Matching**: [Best Practices](https://cloud.google.com/dialogflow/docs/intents-best-practices)
- **Amazon Alexa Utterance Patterns**: [Guidelines](https://developer.amazon.com/docs/custom-skills/best-practices-for-sample-utterances-and-custom-slot-type-values.html)

### **SwiftUI MVVM Patterns**
- **Protocol-Oriented Programming**: Swift official guide
- **Async/Await Best Practices**: Apple WWDC 2021
- **Dependency Injection**: [Swift by Sundell](https://www.swiftbysundell.com/articles/different-flavors-of-dependency-injection-in-swift/)

---

## 🚦 **Implementation Checklist**

### **Pre-Implementation**
- [x] Game plan reviewed and approved
- [x] Spec document created
- [x] Handoff updated with reference
- [ ] Todo list created with all tasks
- [ ] Architecture diagram confirmed

### **Phase 1 - Layer 1**
- [ ] Create QueryIntent model
- [ ] Create QueryClassifier with 20 patterns
- [ ] Write unit tests (10+ test cases)
- [ ] Verify pattern matching accuracy

### **Phase 1 - Layer 2**
- [ ] Create HealthDataAnalyzer protocol
- [ ] Create HealthDataAnalysisService implementation
- [ ] Implement 6 core analytics methods
- [ ] Write unit tests for each method
- [ ] Add calculation caching

### **Phase 1 - Layer 3**
- [ ] Create ResponseGenerator with templates
- [ ] Create AnalysisResult model
- [ ] Implement emotion-aware response logic
- [ ] Write unit tests for response formatting

### **Phase 1 - Integration**
- [ ] Extend LifeGPTViewModel with new layers
- [ ] Wire up dependency injection
- [ ] Implement executeQuery method
- [ ] Add emotion detection logic
- [ ] End-to-end integration tests

### **Phase 1 - Testing & QA**
- [ ] Device testing with 10+ queries
- [ ] Verify response accuracy
- [ ] Check emotion-aware theming
- [ ] Performance testing (<500ms responses)
- [ ] Accessibility verification

### **Phase 1 - Documentation**
- [ ] Update handoff with progress
- [ ] Document any deviations from spec
- [ ] Note any new automation opportunities
- [ ] Update success metrics

---

## 📝 **Build Log**

### **Session 1 (Date TBD)**
- Status: Not started
- Progress: 0/3 hours
- Blockers: None
- Notes: Ready to begin

---

## ✅ **Definition of Done**

Phase 1 MVP is complete when:
1. ✅ All 3 layers implemented and tested
2. ✅ ViewModel integration complete
3. ✅ 20+ query patterns working end-to-end
4. ✅ Unit tests passing (90%+ coverage)
5. ✅ Device testing successful
6. ✅ Zero build errors/warnings
7. ✅ Handoff documentation updated
8. ✅ Code committed and pushed to Git

---

**Last Updated:** 2025-10-24
**Next Review:** After Phase 1 completion
