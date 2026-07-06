import SwiftUI
import HarusemKit

/// 레벨 탭: 1레벨부터 순서대로 클리어하며 올라가는 단계 목록.
/// 클리어한 레벨은 다시 플레이할 수 있다 (별 3개 미만으로 끝나면 하트 차감 규칙 동일).
struct LevelsTab: View {
    var model: AppModel
    var goHome: () -> Void
    @State private var limitLevel: Int?

    /// 해금된 레벨 아래로 미리 보여줄 잠긴 레벨 수.
    private static let lockedPreviewCount = 3

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    Section {
                        ForEach(1...model.maxLevel, id: \.self) { n in
                            Button {
                                if model.canOpenLevel(n) {
                                    model.openLevel(n)
                                    goHome()
                                } else {
                                    limitLevel = n
                                }
                            } label: {
                                LevelRow(
                                    level: n,
                                    stars: model.bestStars[n],
                                    isCurrent: n == model.maxLevel,
                                    locked: false
                                )
                            }
                            .buttonStyle(.plain)
                            .id(n)
                        }
                        ForEach(model.maxLevel + 1...model.maxLevel + Self.lockedPreviewCount,
                                id: \.self) { n in
                            LevelRow(level: n, stars: nil, isCurrent: false, locked: true)
                        }
                    } footer: {
                        Text("Clear a level with at least one star to unlock the next.")
                    }
                }
                .scrollContentBackground(.hidden)
                .background(AppBackground())
                .navigationTitle(Text("Levels"))
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    proxy.scrollTo(model.maxLevel, anchor: .center)
                }
                .playLimitAlert(model: model, limitLevel: $limitLevel)
            }
        }
    }
}

private struct LevelRow: View {
    let level: Int
    let stars: Int?
    let isCurrent: Bool
    let locked: Bool

    var body: some View {
        HStack(spacing: 14) {
            // 레벨 번호 배지: 현재 = 브랜드, 클리어 = 골드, 잠김 = 회색
            Text(verbatim: "\(level)")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .frame(width: 44, height: 44)
                .background(badgeBackground)
                .foregroundStyle(badgeForeground)

            VStack(alignment: .leading, spacing: 3) {
                Text("Level \(level)")
                    .fontWeight(isCurrent ? .bold : .medium)
                if isCurrent {
                    Text("Continue")
                        .font(.caption)
                        .foregroundStyle(Theme.brand)
                }
            }

            Spacer()

            if let stars {
                StarsRow(earned: stars, size: 14)
            }

            if locked {
                LockIcon(size: 16)
            } else if stars != nil {
                // 클리어한 레벨: 다시 플레이
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isCurrent ? Theme.brand : Color(.tertiaryLabel))
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .opacity(locked ? 0.45 : 1)
    }

    private var badgeBackground: some View {
        ZStack {
            if isCurrent {
                RoundedRectangle(cornerRadius: 16).fill(Theme.brandGradient)
                    .shadow(color: Theme.brand.opacity(0.35), radius: 6, y: 3)
            } else if stars != nil {
                RoundedRectangle(cornerRadius: 16).fill(Theme.levelGradient(level))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5)
                            .padding(2)
                    )
            } else {
                RoundedRectangle(cornerRadius: 16).fill(Theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.hairline))
            }
        }
    }

    private var badgeForeground: Color {
        if isCurrent || stars != nil { return .white }
        return locked ? Color(.tertiaryLabel) : .primary
    }
}
