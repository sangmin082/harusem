import SwiftUI
import HarusemKit

/// 하루 5문제 완료 후 결과 요약 + 공유.
struct ResultsView: View {
    var model: AppModel

    private var session: DailySession { model.session }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(verbatim: "🎉")
                .font(.system(size: 64))
            if model.isBonusPlay {
                Text("Bonus complete!")
                    .font(.largeTitle.bold())
            } else {
                Text("Day complete!")
                    .font(.largeTitle.bold())
            }
            Text("\(session.totalStars)/\(session.maxStars) stars")
                .font(.title3)
                .foregroundStyle(.secondary)

            if model.isBonusPlay {
                Text("Bonus puzzle \(model.currentBonusNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if model.isArchivePlay {
                Text(verbatim: session.daily.dateKey)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            } else if model.currentStreak > 1 {
                HStack(spacing: 4) {
                    Text(verbatim: "🔥")
                    Text("\(model.currentStreak) day streak")
                }
                .font(.subheadline.weight(.semibold))
            }

            VStack(spacing: 8) {
                ForEach(0..<session.daily.puzzles.count, id: \.self) { index in
                    let earned = session.stars[index] ?? 0
                    HStack {
                        Text(verbatim: "#\(index + 1)")
                            .foregroundStyle(.secondary)
                            .frame(width: 32, alignment: .leading)
                        Text("\(session.daily.puzzles[index].target)")
                            .monospacedDigit()
                        Spacer()
                        Text(verbatim: String(repeating: "★", count: earned)
                             + String(repeating: "☆", count: 3 - earned))
                            .foregroundStyle(.yellow)
                    }
                    .font(.body.weight(.medium))
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))

            if model.isBonusPlay {
                Button {
                    model.startBonusViaAd()
                } label: {
                    Label("Watch an ad for one more puzzle", systemImage: "play.rectangle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!model.ads.rewardedReady)

                Button {
                    model.exitBonus()
                } label: {
                    Label("Back to results", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
            } else if model.isArchivePlay {
                Button {
                    model.exitArchive()
                } label: {
                    Label("Back to today", systemImage: "chevron.left")
                }
                .buttonStyle(.borderedProminent)
            } else {
                ShareLink(item: model.shareTextWithStreak) {
                    Label("Share result", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)

                // 광고 보고 보너스 문제 계속 풀기
                Button {
                    model.startBonusViaAd()
                } label: {
                    Label("Watch an ad for one more puzzle", systemImage: "play.rectangle")
                }
                .buttonStyle(.bordered)
                .disabled(!model.ads.rewardedReady)

                if model.records.daysPlayed > 1 {
                    Text("Days played: \(model.records.daysPlayed) · Total stars: \(model.records.totalStars)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text("New puzzles arrive tomorrow.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(24)
    }
}
