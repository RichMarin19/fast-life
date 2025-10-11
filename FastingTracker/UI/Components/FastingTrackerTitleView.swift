import SwiftUI

struct FastingTrackerTitleView: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("Fast")
                .font(.system(size: 36, weight: .thin, design: .serif))
                .foregroundColor(Color("FLPrimary"))

            Text(" LIFe")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundColor(Color("FLSecondary"))
        }
        .padding(.bottom, 10)
    }
}