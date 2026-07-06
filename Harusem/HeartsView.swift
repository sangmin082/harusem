import SwiftUI
import HarusemKit

/// 상단 고정 상태 바: 왼쪽 레벨/총 별/스트릭, 오른쪽 하트+충전 카운트다운.
struct StatusBar: View {
    var model: AppModel
    let onHeartsTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // 현재 레벨
            Text(verbatim: "Lv.\(model.level)")
                .monospacedDigit()
                .fontWeight(.semibold)
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(.secondarySystemBackground)))
                .accessibilityLabel(Text("Level \(model.level)"))

            // 모은 별 합계
            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text(verbatim: "\(model.totalStarsEarned)")
                    .monospacedDigit()
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color(.secondarySystemBackground)))
            .accessibilityLabel(Text("Total stars: \(model.totalStarsEarned)"))

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
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)

    var body: some View {
        VStack(spacing: 20) {
            Text("Hearts")
                .font(.title2.bold())
                .padding(.top, 24)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<HeartBank.capacity, id: \.self) { index in
                    Image(systemName: index < model.hearts ? "heart.fill" : "heart")
                        .font(.system(size: 26))
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 32)
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
                Text("Hearts refill every 10 minutes.")
                Text("Finish a puzzle with all 3 stars to keep your hearts.")
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
