import SwiftUI
import HarusemKit

/// 레벨 종료 화면: 클리어(별 1개 이상) 또는 실패(별 0개).
struct LevelResultView: View {
    var model: AppModel
    @State private var appeared = false

    private var stars: Int { model.session.totalStars }
    private var cleared: Bool { stars >= 1 }

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            Group {
                if cleared {
                    ClearBadge(size: 116)
                } else {
                    MissBadge(size: 116)
                }
            }
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)

            if cleared {
                Text("Level \(model.level) cleared!")
                    .font(.largeTitle.bold())
            } else {
                Text("So close!")
                    .font(.largeTitle.bold())
            }

            HStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { index in
                    StarIcon(filled: index < stars, size: 42)
                        .scaleEffect(appeared ? 1 : 0.2)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.45).delay(0.15 + Double(index) * 0.12),
                                   value: appeared)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(stars)/3 stars"))

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
                HStack(spacing: 5) {
                    HeartIcon(size: 14)
                    Text(verbatim: "−1")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .chipBackground()
                .accessibilityLabel(Text("One heart lost"))
            } else {
                Label("Perfect — no heart lost!", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.success)
            }

            VStack(spacing: 12) {
                if cleared {
                    Button {
                        model.advanceToNextLevel()
                    } label: {
                        Label("Next level", systemImage: "arrow.right")
                    }
                    .buttonStyle(ProminentButtonStyle())

                    HStack(spacing: 12) {
                        Button {
                            model.retryLevel()
                        } label: {
                            Label("Play again", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(SoftButtonStyle())

                        ShareLink(item: model.shareText) {
                            Label("Share result", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(SoftButtonStyle())
                    }
                } else {
                    Button {
                        model.retryLevel()
                    } label: {
                        Label("Try again", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(ProminentButtonStyle())
                }
            }
            .padding(.top, 6)

            // 누적 성과 요약
            HStack(spacing: 10) {
                HStack(spacing: 5) {
                    StarIcon(size: 13)
                    Text(verbatim: "\(model.totalStarsEarned)")
                        .monospacedDigit()
                        .fontWeight(.semibold)
                }
                .chipBackground()
                HStack(spacing: 5) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.goldGradient)
                    Text(verbatim: "Lv.\(model.maxLevel)")
                        .monospacedDigit()
                        .fontWeight(.semibold)
                }
                .chipBackground()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Total stars: \(model.totalStarsEarned), highest level: \(model.maxLevel)"))

            Spacer()
        }
        .padding(24)
        .overlay(alignment: .topLeading) {
            // 홈(레벨 맵)으로 복귀
            Button {
                model.exitToHome()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.brand)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle().fill(Theme.surface)
                            .overlay(Circle().strokeBorder(Theme.hairline))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Back"))
            .padding(.leading, 20)
            .padding(.top, 8)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5)) {
                appeared = true
            }
        }
    }
}
