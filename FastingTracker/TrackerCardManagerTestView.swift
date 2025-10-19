import SwiftUI

/// DEBUG VIEW - Test TrackerCardManager Layer 1 Infrastructure
/// This view allows manual testing of card manager functionality
/// TODO: Remove before production release
struct TrackerCardManagerTestView: View {
    @ObservedObject private var cardManager = TrackerCardManager.shared

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Layer 1 Infrastructure Test")) {
                    Text("Testing TrackerCardManager singleton")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("All Card Types")) {
                    ForEach(TrackerCardType.allCases) { cardType in
                        VStack(alignment: .leading, spacing: 8) {
                            // Card info
                            HStack {
                                Text(cardType.displayName)
                                    .font(.headline)
                                Spacer()

                                // Visibility indicator
                                Circle()
                                    .fill(cardManager.isCardVisible(cardType) ? Color.green : Color.red)
                                    .frame(width: 12, height: 12)

                                Text(cardManager.isCardVisible(cardType) ? "Visible" : "Hidden")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text(cardType.description)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            // Test controls
                            HStack(spacing: 12) {
                                // Visibility toggle
                                Button(action: {
                                    let newState = !cardManager.isCardVisible(cardType)
                                    cardManager.setCardVisibility(cardType, isVisible: newState)
                                }) {
                                    Label(
                                        cardManager.isCardVisible(cardType) ? "Hide" : "Show",
                                        systemImage: cardManager.isCardVisible(cardType) ? "eye.slash" : "eye"
                                    )
                                    .font(.caption)
                                }
                                .buttonStyle(.bordered)

                                // Expansion toggle
                                Button(action: {
                                    cardManager.toggleCardExpansion(cardType)
                                }) {
                                    Label(
                                        cardManager.isCardExpanded(cardType) ? "Collapse" : "Expand",
                                        systemImage: cardManager.isCardExpanded(cardType) ? "chevron.up" : "chevron.down"
                                    )
                                    .font(.caption)
                                }
                                .buttonStyle(.bordered)

                                // Order info
                                Text("Order: \(cardManager.getCardOrder(cardType))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Test Results")) {
                    // Total cards
                    HStack {
                        Text("Total Cards")
                        Spacer()
                        Text("\(TrackerCardType.allCases.count)")
                            .foregroundColor(.secondary)
                    }

                    // Visible count
                    HStack {
                        Text("Visible Cards")
                        Spacer()
                        Text("\(cardManager.getVisibleCardsInOrder().count)")
                            .foregroundColor(cardManager.getVisibleCardsInOrder().count > 0 ? .green : .red)
                    }

                    // Hidden count
                    HStack {
                        Text("Hidden Cards")
                        Spacer()
                        let hiddenCount = TrackerCardType.allCases.count - cardManager.getVisibleCardsInOrder().count
                        Text("\(hiddenCount)")
                            .foregroundColor(hiddenCount > 0 ? .orange : .secondary)
                    }
                }

                // REMOVED: Backwards Compatibility Check section
                // Legacy keys are now internal to TrackerCardManager - migration handled automatically
                // Single source of truth: All visibility checks use cardManager.isCardVisible()

                Section(header: Text("Actions")) {
                    Button("Reset All to Default") {
                        cardManager.resetAllCards()
                    }
                    .foregroundColor(.red)

                    Button("Hide All Cards") {
                        for cardType in TrackerCardType.allCases {
                            cardManager.hideCard(cardType)
                        }
                    }

                    Button("Show All Cards") {
                        for cardType in TrackerCardType.allCases {
                            cardManager.showCard(cardType)
                        }
                    }
                }
            }
            .navigationTitle("Card Manager Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    TrackerCardManagerTestView()
}
