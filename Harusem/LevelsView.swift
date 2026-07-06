import SwiftUI
import HarusemKit

/// 레벨 탭: 1레벨부터 순서대로 클리어하며 올라가는 단계 목록.
/// 클리어한 레벨은 다시 플레이할 수 있다 (별 3개 미만으로 끝나면 하트 차감 규칙 동일).
struct LevelsTab: View {
    var model: AppModel
    var goHome: () -> Void

    /// 해금된 레벨 아래로 미리 보여줄 잠긴 레벨 수.
    private static let lockedPreviewCount = 3

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    Section {
                        ForEach(1...model.maxLevel, id: \.self) { n in
                            Button {
                                model.openLevel(n)
                                goHome()
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
                .navigationTitle(Text("Levels"))
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    proxy.scrollTo(model.maxLevel, anchor: .center)
                }
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
        HStack(spacing: 12) {
            Text(verbatim: "\(level)")
                .font(.headline)
                .monospacedDigit()
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(isCurrent ? Color.accentColor : Color(.secondarySystemBackground))
                )
                .foregroundStyle(isCurrent ? Color.white : Color.primary)

            Text("Level \(level)")
                .fontWeight(isCurrent ? .semibold : .regular)

            Spacer()

            if let stars {
                Text(verbatim: String(repeating: "★", count: stars)
                     + String(repeating: "☆", count: 3 - stars))
                    .foregroundStyle(.yellow)
            }

            if locked {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
            } else if stars != nil {
                // 클리어한 레벨: 다시 플레이
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
        .opacity(locked ? 0.45 : 1)
    }
}
