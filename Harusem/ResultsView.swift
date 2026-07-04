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
            Text("Day complete!")
                .font(.largeTitle.bold())
            Text("\(session.totalStars)/\(session.maxStars) stars")
                .font(.title3)
                .foregroundStyle(.secondary)

            if model.currentStreak > 1 {
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

            ShareLink(item: session.shareText()) {
                Label("Share result", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)

            if model.records.daysPlayed > 1 {
                Text("Days played: \(model.records.daysPlayed) · Total stars: \(model.records.totalStars)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text("New puzzles arrive tomorrow.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(24)
    }
}
