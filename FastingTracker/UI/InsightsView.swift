import SwiftUI

struct InsightsView: View {
    @State private var selectedSection: InsightSection = .essentials

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Section Picker
                    Picker("Section", selection: $selectedSection) {
                        ForEach(InsightSection.allCases, id: \.self) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Content based on selection
                    switch selectedSection {
                    case .essentials:
                        EssentialsSection()
                    case .timeline:
                        FastingTimelineSection()
                    case .faq:
                        FAQSection()
                    case .myths:
                        MythBustersSection()
                    case .terms:
                        GlossarySection()
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Insights")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        .navigationViewStyle(.stack)
    }
}

enum InsightSection: String, CaseIterable {
    case essentials = "Essentials"
    case timeline = "Timeline"
    case faq = "FAQ"
    case myths = "Myths"
    case terms = "Terms"
}

// MARK: - Essentials Section

struct EssentialsSection: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color("FLSuccess"))
                Text("The 80/20 Rule")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("20% of actions deliver 80% of results")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            // Key Principles
            VStack(spacing: 12) {
                EssentialCard(
                    icon: "clock.fill",
                    color: Color("FLSecondary"),
                    title: "Fasting Window",
                    description: "The specific hours you abstain from food. Popular schedules are 16:8 (16 hours fasting, 8 hours eating)."
                )

                EssentialCard(
                    icon: "checkmark.circle.fill",
                    color: Color("FLSuccess"),
                    title: "Consistency Over Perfection",
                    description: "Sticking to your schedule most days is far more powerful than occasional strict fasting."
                )

                EssentialCard(
                    icon: "drop.fill",
                    color: Color("FLPrimary"),
                    title: "Hydration",
                    description: "Drinking water, black coffee, or tea during fasting is essential and keeps you feeling full."
                )

                EssentialCard(
                    icon: "leaf.fill",
                    color: Color("FLSuccess"),
                    title: "Food Quality Matters",
                    description: "While fasting helps control when you eat, food quality—lean protein, vegetables, whole foods—makes or breaks results."
                )

                EssentialCard(
                    icon: "heart.fill",
                    color: Color("FLWarning"),
                    title: "Listen to Your Body",
                    description: "Hunger adaptation takes time. Start gradually and adjust your eating window as needed."
                )
            }
            .padding(.horizontal)

            // Bottom Line
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("Bottom Line")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Text("Focus on choosing a fasting schedule you can stick with, stay hydrated, eat whole foods, and give your body time to adapt. That's the 20% that gives 80% of the benefits.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

struct EssentialCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Fasting Timeline Section

struct FastingTimelineSection: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 40))
                    .foregroundColor(Color("FLSecondary"))
                Text("Fasting Timeline")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("What happens in your body during fasting")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            // Timeline Cards
            VStack(spacing: 12) {
                ForEach(FastingStage.all) { stage in
                    TimelineStageCard(stage: stage)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct TimelineStageCard: View {
    let stage: FastingStage
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Text(stage.icon)
                        .font(.system(size: 36))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(stage.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text(stage.hourRange + " hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .foregroundColor(Color("FLSecondary"))
                        .font(.title3)
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    // Description points
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(stage.description, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("FLSecondary"))
                                Text(point)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // Did You Know
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.subheadline)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Did You Know?")
                                .font(.caption)
                                .fontWeight(.bold)
                            Text(stage.didYouKnow)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - FAQ Section

struct FAQSection: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color("FLSecondary"))
                Text("Frequently Asked Questions")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Your top questions answered")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            // FAQ Items
            VStack(spacing: 12) {
                FAQItem(
                    question: "Can I drink water during my fast?",
                    answer: "Yes! Water, black coffee, and plain tea are encouraged during fasting. They help keep you hydrated and can reduce hunger without breaking your fast."
                )

                FAQItem(
                    question: "Will fasting slow down my metabolism?",
                    answer: "No. Short-term fasting (16-24 hours) actually increases metabolism slightly. Metabolic slowdown typically only occurs with prolonged caloric restriction over weeks or months."
                )

                FAQItem(
                    question: "Can I exercise while fasting?",
                    answer: "Yes! Many people exercise during their fasting window. Light to moderate exercise is generally fine. Listen to your body and stay hydrated."
                )

                FAQItem(
                    question: "What if I get hungry during my fast?",
                    answer: "Hunger comes in waves and typically passes after 15-20 minutes. Drink water, stay busy, and remember that hunger adaptation improves over time."
                )

                FAQItem(
                    question: "How long until I see results?",
                    answer: "Most people notice increased energy and mental clarity within 1-2 weeks. Weight loss and metabolic benefits typically become noticeable after 3-4 weeks of consistent fasting."
                )

                FAQItem(
                    question: "Do I need to fast every day?",
                    answer: "No. Consistency matters more than perfection. Aim for 5-6 days per week to see results. It's okay to take breaks for special occasions or when your body needs rest."
                )

                FAQItem(
                    question: "Can I take medications during fasting?",
                    answer: "Always consult your doctor about medications and fasting. Some medications need to be taken with food. Never stop or change medications without medical guidance."
                )

                FAQItem(
                    question: "What should I eat when breaking my fast?",
                    answer: "Start with something light and nutritious. Good options include fruits, vegetables, lean protein, or a small balanced meal. Avoid binge eating or heavy, processed foods."
                )

                FAQItem(
                    question: "Is intermittent fasting safe for everyone?",
                    answer: "While generally safe for healthy adults, IF isn't recommended for pregnant/nursing women, children, people with eating disorders, or those with certain medical conditions. Always consult a healthcare provider."
                )

                FAQItem(
                    question: "What's the difference between 16:8 and OMAD?",
                    answer: "16:8 means 16 hours fasting with an 8-hour eating window (like 12pm-8pm). OMAD (One Meal A Day) is stricter—you eat all daily calories in one sitting within 1-2 hours."
                )
            }
            .padding(.horizontal)
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .foregroundColor(Color("FLSecondary"))
                        .font(.title3)
                }
            }

            if isExpanded {
                Text(answer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Myth Busters Section

struct MythBustersSection: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.orange)
                Text("Myth Busters")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Separating fact from fiction")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            // Myth Cards
            VStack(spacing: 12) {
                MythCard(
                    myth: "Skipping breakfast ruins your metabolism",
                    truth: "Your metabolism doesn't shut down from missing breakfast. Meal timing matters less than total daily nutrition. Many successful fasters skip breakfast entirely."
                )

                MythCard(
                    myth: "You'll lose all your muscle mass",
                    truth: "Short-term fasting actually preserves muscle by increasing growth hormone. Muscle loss only occurs with prolonged caloric deficit combined with no exercise."
                )

                MythCard(
                    myth: "Fasting puts your body in 'starvation mode'",
                    truth: "Starvation mode is a myth for short-term fasting. Your body has plenty of stored energy. Metabolic adaptation only occurs after weeks of severe caloric restriction."
                )

                MythCard(
                    myth: "You need to eat every 2-3 hours to stay healthy",
                    truth: "Your body is designed to go without food for extended periods. Frequent eating can actually lead to insulin resistance. Fasting gives your digestive system a healthy rest."
                )

                MythCard(
                    myth: "Fasting causes nutritional deficiencies",
                    truth: "If you eat nutrient-dense whole foods during your eating window, you can meet all nutritional needs. Quality matters more than quantity of meals."
                )

                MythCard(
                    myth: "Coffee and tea break your fast",
                    truth: "Black coffee and plain tea don't break your fast. They contain almost zero calories and can actually enhance fat burning and autophagy."
                )

                MythCard(
                    myth: "Fasting makes you tired and weak",
                    truth: "After adaptation (1-2 weeks), most people report increased energy and mental clarity. Your body becomes efficient at using stored fat for fuel."
                )

                MythCard(
                    myth: "You can eat anything during your eating window",
                    truth: "While fasting helps with calorie control, food quality still matters. Junk food during your eating window will undermine health benefits."
                )
            }
            .padding(.horizontal)
        }
    }
}

struct MythCard: View {
    let myth: String
    let truth: String
    @State private var showTruth = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red)

                VStack(alignment: .leading, spacing: 8) {
                    Text("MYTH")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)

                    Text(myth)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }

            Divider()

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color("FLSuccess"))

                VStack(alignment: .leading, spacing: 8) {
                    Text("TRUTH")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color("FLSuccess"))

                    Text(truth)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Glossary Section

struct GlossarySection: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.purple)
                Text("Key Terms")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Essential fasting terminology")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            // Glossary Items
            VStack(spacing: 12) {
                GlossaryItem(
                    term: "Intermittent Fasting (IF)",
                    definition: "An eating pattern that cycles between periods of fasting and eating. It's not about what you eat, but when you eat."
                )

                GlossaryItem(
                    term: "Fasting Window",
                    definition: "The period when you abstain from food but may drink water, black coffee, or plain tea without breaking your fast."
                )

                GlossaryItem(
                    term: "Eating Window",
                    definition: "The timeframe when all your meals are consumed. For example, in 16:8 fasting, your eating window might be 12pm-8pm."
                )

                GlossaryItem(
                    term: "16:8 Method",
                    definition: "16 hours fasting, 8 hours eating. The most popular IF schedule. Example: Fast from 8pm to 12pm, eat from 12pm to 8pm."
                )

                GlossaryItem(
                    term: "OMAD",
                    definition: "One Meal A Day – a stricter approach where all daily calories are consumed in one sitting within a 1-2 hour window."
                )

                GlossaryItem(
                    term: "Ketosis",
                    definition: "A metabolic state when the body burns fat for fuel instead of carbohydrates. Often achieved through fasting or low-carb diets."
                )

                GlossaryItem(
                    term: "Autophagy",
                    definition: "A cellular cleanup process triggered by fasting (typically after 16+ hours) where the body removes damaged cells and regenerates new ones. Think of it as your body's recycling system."
                )

                GlossaryItem(
                    term: "Insulin Sensitivity",
                    definition: "How effectively your cells respond to insulin. Fasting improves insulin sensitivity, helping regulate blood sugar and reduce diabetes risk."
                )

                GlossaryItem(
                    term: "Growth Hormone (HGH)",
                    definition: "A hormone that increases during fasting, helping preserve muscle mass and promote fat burning. Can increase by up to 500% during a 24-hour fast."
                )

                GlossaryItem(
                    term: "Breaking Your Fast",
                    definition: "The first meal after your fasting period. Best done with nutrient-dense, whole foods rather than processed or sugary foods."
                )
            }
            .padding(.horizontal)
        }
    }
}

struct GlossaryItem: View {
    let term: String
    let definition: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(term)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.purple)

            Text(definition)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}
