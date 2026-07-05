import SwiftUI
import HarusemKit

/// 하트 상태 시트: 보유량, 다음 충전까지 남은 시간, 광고 충전.
struct HeartsView: View {
    var model: AppModel
    @Environment(\.dismiss) private var dismiss

    private let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Text("Hearts")
                .font(.title2.bold())
                .padding(.top, 24)

            HStack(spacing: 8) {
                ForEach(0..<HeartBank.capacity, id: \.self) { index in
                    Image(systemName: index < model.hearts ? "heart.fill" : "heart")
                        .font(.system(size: 30))
                        .foregroundStyle(.red)
                }
            }
            .accessibilityLabel(Text("Hearts: \(model.hearts)"))

            if let minutes = model.nextHeartMinutes {
                Text("Next heart: \(minutes) min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            VStack(spacing: 6) {
                Text("Hearts refill every 30 minutes.")
                Text("Finish with all 3 stars to keep your hearts.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Button {
                model.refillHeartViaAd()
            } label: {
                Label("Watch an ad to refill a heart", systemImage: "play.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!model.ads.rewardedReady || model.hearts >= HeartBank.capacity)

            Spacer()
        }
        .padding(24)
        .presentationDetents([.medium])
        .onReceive(timer) { _ in
            model.refreshHearts()
        }
    }
}
