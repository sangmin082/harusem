import SwiftUI
import HarusemKit

/// 홈 탭: 레벨 맵. 위로는 잠긴 다음 레벨들(흐림 + 자물쇠), 가운데 현재 도전 레벨(큰 카드),
/// 아래로 완료한 레벨들이 내려간다. 박스를 누르면 플레이 화면으로 진입한다.
struct LevelHomeView: View {
    var model: AppModel
    @State private var limitLevel: Int?

    /// 현재 레벨 위로 미리 보여줄 잠긴 레벨 수.
    private static let lockedPreviewCount = 3

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    // 잠긴 레벨: 먼 레벨부터 위에 쌓여 내려온다 (5, 4, 3 → 현재 2 바로 위가 3)
                    ForEach(lockedLevelsDescending, id: \.self) { n in
                        LockedLevelCard(level: n)
                    }

                    CurrentLevelCard(
                        level: model.maxLevel,
                        inProgress: model.level == model.maxLevel && model.hasProgress,
                        playsRemaining: model.playsRemaining(for: model.maxLevel)
                    ) {
                        open(model.maxLevel)
                    }
                    .id("current")

                    ForEach(clearedLevelsDescending, id: \.self) { n in
                        ClearedLevelCard(
                            level: n,
                            stars: model.bestStars[n] ?? 0,
                            playsRemaining: model.playsRemaining(for: n)
                        ) {
                            open(n)
                        }
                    }
                }
                .padding(20)
            }
            .onAppear {
                // 현재 레벨 카드가 화면 가운데 오도록
                proxy.scrollTo("current", anchor: .center)
            }
        }
        .playLimitAlert(model: model, limitLevel: $limitLevel)
    }

    private func open(_ n: Int) {
        if model.canOpenLevel(n) {
            model.openLevel(n)
        } else {
            limitLevel = n
        }
    }

    private var lockedLevelsDescending: [Int] {
        stride(from: model.maxLevel + Self.lockedPreviewCount,
               through: model.maxLevel + 1, by: -1).map { $0 }
    }

    private var clearedLevelsDescending: [Int] {
        stride(from: model.maxLevel - 1, through: 1, by: -1).map { $0 }
    }
}

/// 아직 잠긴 레벨 (흐림 + 자물쇠).
private struct LockedLevelCard: View {
    let level: Int

    var body: some View {
        HStack(spacing: 14) {
            Text(verbatim: "\(level)")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .foregroundStyle(Color(.tertiaryLabel))
                .frame(width: 42, height: 42)
                .background(
                    Circle().fill(Theme.surface)
                        .overlay(Circle().strokeBorder(Theme.hairline))
                )

            Text("Level \(level)")
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Spacer()

            Image(systemName: "lock.fill")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .harusemCard(cornerRadius: 18)
        .opacity(0.5)
        .accessibilityElement(children: .combine)
    }
}

/// 현재 도전 레벨 (브랜드 그라디언트 큰 카드).
private struct CurrentLevelCard: View {
    let level: Int
    let inProgress: Bool
    let playsRemaining: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(verbatim: "\(level)")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Theme.brand)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color.white))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(level)")
                        .font(.title3.bold())
                    Text(inProgress ? "Continue" : "Tap to play")
                        .font(.subheadline)
                        .opacity(0.85)
                }

                Spacer()

                if playsRemaining < AppModel.dailyPlaysPerLevel {
                    PlaysChip(remaining: playsRemaining, onDark: true)
                }

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
            }
            .foregroundStyle(.white)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Theme.brandGradient)
                    .shadow(color: Theme.brand.opacity(0.35), radius: 12, y: 6)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Level \(level)"))
    }
}

/// 완료한 레벨 (별 기록 + 다시 플레이).
private struct ClearedLevelCard: View {
    let level: Int
    let stars: Int
    let playsRemaining: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(verbatim: "\(level)")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Theme.levelGradient(level)))

                Text("Level \(level)")
                    .fontWeight(.medium)

                Spacer()

                if playsRemaining < AppModel.dailyPlaysPerLevel {
                    PlaysChip(remaining: playsRemaining, onDark: false)
                }

                StarsRow(earned: stars, size: 15)

                Image(systemName: playsRemaining == 0 ? "play.rectangle.fill" : "arrow.counterclockwise")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .harusemCard(cornerRadius: 18)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Level \(level)"))
    }
}

/// 오늘 남은 플레이 횟수 칩 (3회 미만으로 줄었을 때만 표시).
struct PlaysChip: View {
    let remaining: Int
    var onDark = false

    var body: some View {
        Text(verbatim: "\(remaining)/\(AppModel.dailyPlaysPerLevel)")
            .font(.caption2.bold())
            .monospacedDigit()
            .foregroundStyle(onDark ? Color.white : Color.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(onDark ? Color.white.opacity(0.22) : Color.black.opacity(0.06))
            )
            .accessibilityLabel(Text("Plays left today: \(remaining)"))
    }
}

// MARK: - 플레이 횟수 소진 안내

extension View {
    /// 플레이 횟수 소진 알림: 광고로 1회 추가 제안.
    func playLimitAlert(model: AppModel, limitLevel: Binding<Int?>) -> some View {
        alert(
            Text("No plays left today"),
            isPresented: Binding(
                get: { limitLevel.wrappedValue != nil },
                set: { if !$0 { limitLevel.wrappedValue = nil } }
            )
        ) {
            Button {
                if let n = limitLevel.wrappedValue {
                    model.earnPlayViaAd(level: n)
                }
            } label: {
                Text("Watch an ad for one more try")
            }
            .disabled(!model.ads.rewardedReady)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can play each level 3 times a day. Watch an ad for one more try.")
        }
    }
}
