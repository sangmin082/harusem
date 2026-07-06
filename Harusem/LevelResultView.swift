import SwiftUI
import HarusemKit

/// 레벨 종료 화면: 클리어(별 1개 이상) 또는 실패(별 0개).
struct LevelResultView: View {
    var model: AppModel

    private var stars: Int { model.session.totalStars }
    private var cleared: Bool { stars >= 1 }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(verbatim: cleared ? "🎉" : "😅")
                .font(.system(size: 64))

            if cleared {
                Text("Level \(model.level) cleared!")
                    .font(.largeTitle.bold())
            } else {
                Text("So close!")
                    .font(.largeTitle.bold())
            }

            Text(verbatim: String(repeating: "★", count: stars)
                 + String(repeating: "☆", count: 3 - stars))
                .font(.system(size: 40))
                .foregroundStyle(.yellow)

            if !cleared {
                Text("You reached \(model.session.game.closestValue) — target was \(model.session.currentPuzzle.target).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Text("Reach at least one star to clear the level.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if stars < 3 {
                // 만점이 아니면 하트 1개 차감됨을 알려준다
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text(verbatim: "−1")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color(.secondarySystemBackground)))
                .accessibilityLabel(Text("One heart lost"))
            } else {
                Text("Perfect — no heart lost!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 12) {
                if cleared {
                    Button {
                        model.advanceToNextLevel()
                    } label: {
                        Label("Next level", systemImage: "arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        model.retryLevel()
                    } label: {
                        Label("Play again", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    ShareLink(item: model.shareText) {
                        Label("Share result", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        model.retryLevel()
                    } label: {
                        Label("Try again", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(.top, 8)

            Text(verbatim: "⭐️ \(model.totalStarsEarned) · 🏔️ \(model.maxLevel)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text("Total stars: \(model.totalStarsEarned), highest level: \(model.maxLevel)"))

            Spacer()
        }
        .padding(24)
    }
}
