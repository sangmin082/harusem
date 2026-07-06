import SwiftUI
import HarusemKit

struct PuzzleScreen: View {
    var model: AppModel
    @State private var showSubmitConfirm = false
    @State private var showHelp = false
    @AppStorage("harusem.hasSeenHelp") private var hasSeenHelp = false

    private var session: DailySession { model.session }

    private var starsPreview: String {
        let n = session.game.starRating
        return String(repeating: "★", count: n) + String(repeating: "☆", count: 3 - n)
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center, spacing: 12) {
                Text("Level \(model.level)")
                    .font(.headline)
                if let best = model.bestStarsForCurrentLevel {
                    // 이미 클리어한 레벨 다시 플레이 중: 최고 기록 표시
                    Text(verbatim: String(repeating: "★", count: best)
                         + String(repeating: "☆", count: 3 - best))
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
                Spacer()
                Button {
                    showHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                }
                .accessibilityLabel(Text("How to play"))
            }
            targetSection
            Spacer(minLength: 8)
            if model.needsHeartToPlay {
                OutOfHeartsCard(model: model)
            } else {
                TileGrid(model: model)
                OperatorRow(model: model)
            }
            Spacer(minLength: 8)
            controls
        }
        .padding(20)
        .sensoryFeedback(.error, trigger: model.rejectionCount)
        .sensoryFeedback(.success, trigger: session.game.isSolved)
        .sheet(isPresented: $showHelp) { HelpView() }
        .onAppear {
            if !hasSeenHelp {
                showHelp = true
                hasSeenHelp = true
            }
        }
        .confirmationDialog(
            Text("Finish this puzzle with \(starsPreview)?"),
            isPresented: $showSubmitConfirm,
            titleVisibility: .visible
        ) {
            Button("Submit") { model.submit() }
            Button("Keep trying", role: .cancel) {}
        }
    }

    private var targetSection: some View {
        VStack(spacing: 4) {
            Text("Target")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(session.currentPuzzle.target)")
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            Group {
                if session.game.isSolved {
                    Text("Reached the target!")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                } else if let hint = model.currentHint {
                    Text("Next move: \(hint.description)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .monospacedDigit()
                } else if model.hintDeadEnd {
                    Text("No path from here — try undo.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.orange)
                } else if !session.game.moves.isEmpty {
                    Text("Best so far: \(session.game.closestValue)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .animation(.bouncy, value: session.game.isSolved)
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                model.undo()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(session.game.moves.isEmpty)

            Button {
                model.reset()
            } label: {
                Label("Restart", systemImage: "arrow.counterclockwise")
            }
            .disabled(session.game.moves.isEmpty)

            if model.hintsRemaining == 0 && model.ads.rewardedReady {
                // 힌트 소진 → 리워드 광고 시청으로 1개 충전
                Button {
                    model.earnHintFromAd()
                } label: {
                    Label("Hint", systemImage: "play.rectangle")
                }
                .disabled(session.game.isSolved)
                .accessibilityLabel(Text("Watch an ad for a hint"))
            } else {
                Button {
                    model.useHint()
                } label: {
                    Label {
                        Text(verbatim: "\(model.hintsRemaining)")
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "lightbulb")
                    }
                }
                .disabled(model.hintsRemaining == 0 || session.game.isSolved)
                .accessibilityLabel(Text("Hints left today: \(model.hintsRemaining)"))
            }

            Spacer()

            if session.game.isSolved {
                Button {
                    model.submit()
                } label: {
                    Label("Finish", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Submit") { showSubmitConfirm = true }
                    .buttonStyle(.bordered)
            }
        }
    }
}

/// 하트 소진 시 타일 영역을 대신하는 안내 카드.
private struct OutOfHeartsCard: View {
    var model: AppModel

    var body: some View {
        VStack(spacing: 14) {
            Text(verbatim: "💔")
                .font(.system(size: 52))
            Text("Out of hearts")
                .font(.headline)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                if let countdown = model.nextHeartCountdown(now: context.date) {
                    Text("Next heart in \(countdown)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            Button {
                model.refillHeartViaAd()
            } label: {
                Label("Watch an ad to refill a heart", systemImage: "play.rectangle")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.ads.rewardedReady)
            Text("Hearts refill every 10 minutes.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
    }
}

/// 연산자의 VoiceOver 라벨 (UI 관심사라 앱 타깃에 둔다).
extension Op {
    var accessibilityName: LocalizedStringKey {
        switch self {
        case .add: "Add"
        case .subtract: "Subtract"
        case .multiply: "Multiply"
        case .divide: "Divide"
        }
    }
}

private struct TileGrid: View {
    var model: AppModel
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(model.session.game.tiles) { tile in
                TileButton(tile: tile, isSelected: model.selection.lhsID == tile.id) {
                    model.tapTile(tile.id)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.snappy, value: model.session.game.tiles)
    }
}

private struct TileButton: View {
    let tile: GameState.Tile
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(tile.value)")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .monospacedDigit()
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, minHeight: 72)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct OperatorRow: View {
    var model: AppModel

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Op.allCases, id: \.self) { op in
                let isSelected = model.selection.op == op
                Button {
                    model.tapOp(op)
                } label: {
                    Text(op.rawValue)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                        )
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(op.accessibilityName)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
    }
}
