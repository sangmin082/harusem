import SwiftUI
import HarusemKit

/// 상단 고정 상태 바: 왼쪽 별점/스트릭, 오른쪽 하트+충전 카운트다운.
struct StatusBar: View {
    var model: AppModel
    let onHeartsTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // 현재 세션(오늘/아카이브/보너스)에서 확정한 별
            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text(verbatim: "\(model.session.totalStars)/\(model.session.maxStars)")
                    .monospacedDigit()
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color(.secondarySystemBackground)))
            .accessibilityLabel(Text("\(model.session.totalStars)/\(model.session.maxStars) stars"))

            if model.currentStreak > 1 {
                HStack(spacing: 3) {
                    Text(verbatim: "🔥")
                    Text(verbatim: "\(model.currentStreak)")
                        .monospacedDigit()
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(.secondarySystemBackground)))
                .accessibilityLabel(Text("\(model.currentStreak) day streak"))
            }

            Spacer()

            HeartChip(model: model, action: onHeartsTap)
        }
    }
}

/// 우상단 고정 하트 잔량 칩 + 다음 충전 카운트다운 (초 단위 갱신).
struct HeartChip: View {
    var model: AppModel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text(verbatim: "\(model.hearts)")
                        .monospacedDigit()
                        .fontWeight(.semibold)
                    if let countdown = model.nextHeartCountdown(now: context.date) {
                        Text(verbatim: "· \(countdown)")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color(.secondarySystemBackground)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Hearts: \(model.hearts)"))
    }
}

/// 하트 상태 시트: 보유량, 다음 충전까지 남은 시간, 광고 충전.
struct HeartsView: View {
    var model: AppModel
    @Environment(\.dismiss) private var dismiss

    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

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

            TimelineView(.periodic(from: .now, by: 1)) { context in
                if let countdown = model.nextHeartCountdown(now: context.date) {
                    Text("Next heart in \(countdown)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
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
