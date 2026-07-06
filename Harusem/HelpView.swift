import SwiftUI

/// 게임 방법 안내. 첫 실행 시 자동 표시 + 플레이 화면의 ? 버튼으로 재열람.
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How to play")
                .font(.title.bold())
                .padding(.top, 8)

            ruleRow("plus.forwardslash.minus",
                    "Combine two tiles with +, −, ×, ÷ to make a new number.")
            ruleRow("target",
                    "Reach the target exactly for 3 stars.")
            ruleRow("star.leadinghalf.filled",
                    "Within ±10: 2 stars. Within ±25: 1 star.")
            ruleRow("checkmark.circle",
                    "Results must always be positive whole numbers.")
            ruleRow("arrow.uturn.backward",
                    "Undo anytime. One puzzle per level — clear it to unlock the next.")
            ruleRow("heart.fill",
                    "Finish below 3 stars and you lose one heart. Hearts refill every 10 minutes.")

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Got it")
            }
            .buttonStyle(ProminentButtonStyle())
        }
        .padding(24)
        .presentationDetents([.medium, .large])
    }

    private func ruleRow(_ icon: String, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.brandGradient))
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    HelpView()
}
