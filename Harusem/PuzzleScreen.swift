import SwiftUI
import HarusemKit

struct PuzzleScreen: View {
    var model: AppModel
    @State private var showSubmitConfirm = false

    private var session: DailySession { model.session }

    private var starsPreview: String {
        let n = session.game.starRating
        return String(repeating: "★", count: n) + String(repeating: "☆", count: 3 - n)
    }

    var body: some View {
        VStack(spacing: 20) {
            ProgressHeader(session: session)
            targetSection
            Spacer(minLength: 8)
            TileGrid(model: model)
            OperatorRow(model: model)
            Spacer(minLength: 8)
            controls
        }
        .padding(20)
        .sensoryFeedback(.error, trigger: model.rejectionCount)
        .sensoryFeedback(.success, trigger: session.game.isSolved)
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
            if session.game.isSolved {
                Text("Reached the target!")
                    .font(.headline)
                    .foregroundStyle(.green)
            } else if !session.game.moves.isEmpty {
                Text("Best so far: \(session.game.closestValue)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
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

            Spacer()

            if session.game.isSolved {
                Button {
                    model.submit()
                } label: {
                    Label("Next puzzle", systemImage: "arrow.right")
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Submit") { showSubmitConfirm = true }
                    .buttonStyle(.bordered)
            }
        }
    }
}

/// 상단: 문제별 진행 표시 (확정 별점 / 현재 / 남은 문제).
private struct ProgressHeader: View {
    let session: DailySession

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<session.daily.puzzles.count, id: \.self) { index in
                if let earned = session.stars[index] {
                    Text("★\(earned)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.yellow.opacity(0.25)))
                } else {
                    Circle()
                        .fill(index == session.currentIndex ? Color.accentColor : Color(.systemFill))
                        .frame(width: 10, height: 10)
                }
            }
            Spacer()
            Text("Puzzle \(session.currentIndex + 1) of \(session.daily.puzzles.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
                .font(.system(size: 28, weight: .bold, design: .rounded))
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
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                        )
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
