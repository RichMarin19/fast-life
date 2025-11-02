import SwiftUI

// MARK: - Content Opt-Out System

/// Individual content item that can be opted out
/// Used for granular control over tips, nudges, messages, and summaries
struct ContentItem: Identifiable, Codable, Equatable {
    let id: String
    let category: ContentCategory
    let displayText: String
    var isOptedOut: Bool
    let timestamp: Date

    init(id: String, category: ContentCategory, displayText: String) {
        self.id = id
        self.category = category
        self.displayText = displayText
        self.isOptedOut = true  // Opted out by default when created
        self.timestamp = Date()
    }
}

/// Content categories for organization
enum ContentCategory: String, Codable, CaseIterable {
    case educationalInsights = "educational_insights"
    case behavioralNudges = "behavioral_nudges"
    case motivationalMessages = "motivational_messages"
    case progressSummaries = "progress_summaries"

    var displayName: String {
        switch self {
        case .educationalInsights: return "Educational Insights"
        case .behavioralNudges: return "Behavioral Nudges"
        case .motivationalMessages: return "Motivational Messages"
        case .progressSummaries: return "Your Progress Journey"
        }
    }
}

/// Weight Tracker card types that can be hidden/shown
/// Used in Control Center for managing tracker card visibility
/// Industry Pattern: Enum registry for feature toggles (Spotify, Apple Health)
enum TrackerCardType: String, Codable, CaseIterable, Identifiable {
    case currentWeight = "current_weight_card"
    // REMOVED: milestone card (redundant - Current Weight Card already has milestone features)
    case chart = "chart_card"
    case stats = "stats_card"
    case history = "history_card"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .currentWeight: return "Current Weight"
        // REMOVED: milestone case - functionality exists in Current Weight Card
        case .chart: return "Chart"
        case .stats: return "Statistics"
        case .history: return "History"
        }
    }

    var description: String {
        switch self {
        case .currentWeight: return "Latest weight with progress tracking"
        // REMOVED: milestone case - functionality exists in Current Weight Card
        case .chart: return "Weight trend chart"
        case .stats: return "Weight statistics summary"
        case .history: return "Weight entry history list"
        }
    }

    // REMOVED: visibilityKey - now managed by TrackerCardManager internally
    // All visibility state goes through TrackerCardManager.shared.isCardVisible()
}

// MARK: - TrackerCardType + CardTypeProtocol

extension TrackerCardType: CardTypeProtocol {
    // displayName already exists (lines 52-60)
    // No additional implementation needed - already conforms!
}

/// Progress Story card types that can be hidden/shown
/// Used in Control Center for managing Progress Story card visibility
/// Industry Pattern: Same as TrackerCardType - enum registry for feature toggles
enum ProgressStoryCardType: String, Codable, CaseIterable, Identifiable {
    case coachBar = "progress_story_coach_bar_card"  // v1.2: Coach Bar
    case sevenDay = "progress_story_7day_card"
    case thirtyDay = "progress_story_30day_card"
    case banner = "progress_story_banner_card"
    case reflection = "progress_story_reflection_card"  // v1.2b/v1.2c: Reflection Nudge
    case recap = "progress_story_recap_card"
    case didYouKnow = "progress_story_tip_card"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .coachBar: return "Coach Bar"
        case .sevenDay: return "7-Day Trend"
        case .thirtyDay: return "30-Day Trend"
        case .banner: return "Progress Banner"
        case .reflection: return "Reflection Prompts"
        case .recap: return "Progress Recap"
        case .didYouKnow: return "Did You Know"
        }
    }

    var description: String {
        switch self {
        case .coachBar: return "Behavioral micro-copy under subtitle"
        case .sevenDay: return "7-day weight trend card"
        case .thirtyDay: return "30-day weight trend card"
        case .banner: return "Motivational progress message"
        case .reflection: return "Micro-planning prompts for habit building"
        case .recap: return "Net change, streak, and entries"
        case .didYouKnow: return "Educational weight loss tip"
        }
    }
}

// MARK: - ProgressStoryCardType + CardTypeProtocol

extension ProgressStoryCardType: CardTypeProtocol {
    // displayName already exists (lines 97-106)
    // No additional implementation needed - already conforms!
}

/// Shared opt-out manager accessible from anywhere in the app
/// Industry pattern: Singleton manager for app-wide state (like UserDefaults)
class ContentOptOutManager: ObservableObject {
    static let shared = ContentOptOutManager()

    @AppStorage("optedOutContentItems") private var optedOutContentData: Data = Data()
    @Published var optedOutContentItems: [ContentItem] = []

    private init() {
        loadOptedOutContent()
    }

    /// Load opted-out content items from @AppStorage
    private func loadOptedOutContent() {
        if let decoded = try? JSONDecoder().decode([ContentItem].self, from: optedOutContentData) {
            optedOutContentItems = decoded
        }
    }

    /// Save opted-out content items to @AppStorage
    private func saveOptedOutContent() {
        if let encoded = try? JSONEncoder().encode(optedOutContentItems) {
            optedOutContentData = encoded
        }
    }

    /// Opt out of specific content item
    func optOutContent(id: String, category: ContentCategory, text: String) {
        let newItem = ContentItem(id: id, category: category, displayText: text)

        // Check if already opted out
        if !optedOutContentItems.contains(where: { $0.id == id }) {
            optedOutContentItems.append(newItem)
            saveOptedOutContent()
        }
    }

    /// Opt back in to specific content item
    func optInContent(id: String) {
        optedOutContentItems.removeAll { $0.id == id }
        saveOptedOutContent()
    }

    /// Check if specific content is opted out
    func isContentOptedOut(id: String) -> Bool {
        return optedOutContentItems.contains(where: { $0.id == id })
    }
}

// MARK: - Control Center Card Types

/// Card types for Weight Tracker Control Center
/// User can reorder these based on importance
enum ControlCenterCardType: String, Codable, CaseIterable, Identifiable {
    case goals = "goals"
    case notifications = "notifications"
    case insights = "insights"
    case sync = "sync"
    case history = "history"  // NEW: Weight History (moved from main screen)
    case experience = "experience"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .goals: return "Goals"
        case .notifications: return "Notifications"
        case .insights: return "Insights & Education"
        case .sync: return "Apple Health Sync"
        case .history: return "Weight History"  // NEW
        case .experience: return "Manage My Experience"
        }
    }

    var icon: String {
        switch self {
        case .goals: return "flag.fill"
        case .notifications: return "bell.fill"
        case .insights: return "lightbulb.fill"
        case .sync: return "arrow.triangle.2.circlepath"
        case .history: return "list.bullet.clipboard.fill"  // NEW: History icon
        case .experience: return "slider.horizontal.3"
        }
    }
}
