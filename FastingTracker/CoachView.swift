import SwiftUI

/// CoachView - AI-powered coaching and guidance (Phase 2+ implementation)
/// Placeholder view following Apple SwiftUI patterns
/// Reference: Apple HIG - Navigation and Layout
struct CoachView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 80))
                    .foregroundColor(Color("FLPrimary"))

                Text("AI Coach")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Personalized guidance and coaching coming soon!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Coach")
        }
    }
}

#Preview {
    CoachView()
}