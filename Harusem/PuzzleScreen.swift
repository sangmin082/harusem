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
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 10) {
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

                Text("Level \(model.level)")
                    .font(.title3.bold())
                if let best = model.bestStarsForCurrentLevel {
                    // 이미 클리어한 레벨 다시 플레이 중: 최고 기록 표시
                    StarsRow(earned: best, size: 12)
                }
                Spacer()
                Button {
                    showHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(Text("How to play"))
            }
            targetSection
            Spacer(minLength: 6)
            if model.needsHeartToPlay {
                OutOfHeartsCard(model: model)
            } else {
                TileGrid(model: model)
                OperatorRow(model: model)
            }
            Spacer(minLength: 6)
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
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1.6)
                .foregroundStyle(.secondary)
            Text("\(session.currentPuzzle.target)")
                .font(.system(size: 54, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.brandGradient)
                .contentTransition(.numericText())
            Group {
                if session.game.isSolved {
                    Label("Reached the target!", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.success)
                        .transition(.scale.combined(with: .opacity))
                } else if let hint = model.currentHint {
                    Text("Next move: \(hint.description)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.brand)
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
                } else {
                    // 자리 고정용 (메시지 유무로 레이아웃이 튀지 않게)
                    Text(verbatim: " ")
                        .font(.footnote)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .harusemCard(cornerRadius: 24)
        .overlay(
            // 무지개 포인트 테두리
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Theme.rainbowGradient, lineWidth: 1.5)
                .opacity(0.45)
        )
        .animation(.bouncy, value: session.game.isSolved)
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        HStack(spacing: 10) {
            ControlButton(systemName: "arrow.uturn.backward", title: "Undo") {
                model.undo()
            }
            .disabled(session.game.moves.isEmpty)
            .opacity(session.game.moves.isEmpty ? 0.4 : 1)

            ControlButton(systemName: "arrow.counterclockwise", title: "Restart") {
                model.reset()
            }
            .disabled(session.game.moves.isEmpty)
            .opacity(session.game.moves.isEmpty ? 0.4 : 1)

            if model.hintsRemaining == 0 && model.ads.rewardedReady {
                // 힌트 소진 → 리워드 광고 시청으로 1개 충전
                ControlButton(systemName: "play.rectangle.fill", title: "Hint") {
                    model.earnHintFromAd()
                }
                .disabled(session.game.isSolved)
                .opacity(session.game.isSolved ? 0.4 : 1)
                .accessibilityLabel(Text("Watch an ad for a hint"))
            } else {
                ControlButton(systemName: "lightbulb.fill", badge: model.hintsRemaining, title: "Hint") {
                    model.useHint()
                }
                .disabled(model.hintsRemaining == 0 || session.game.isSolved)
                .opacity(model.hintsRemaining == 0 || session.game.isSolved ? 0.4 : 1)
                .accessibilityLabel(Text("Hints left today: \(model.hintsRemaining)"))
            }

            Spacer()

            if session.game.isSolved {
                Button {
                    model.submit()
                } label: {
                    Label("Finish", systemImage: "checkmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 13)
                        .background(Capsule().fill(Theme.brandGradient)
                            .shadow(color: Theme.brand.opacity(0.3), radius: 8, y: 4))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    showSubmitConfirm = true
                } label: {
                    Text("Submit")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(Theme.surface)
                                .overlay(Capsule().strokeBorder(Theme.hairline))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// 하단 컨트롤 (undo/restart/hint) 원형 버튼.
private struct ControlButton: View {
    let systemName: String
    var badge: Int? = nil
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.brand)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle().fill(Theme.surface)
                            .overlay(Circle().strokeBorder(Theme.hairline))
                    )
                if let badge {
                    Text(verbatim: "\(badge)")
                        .font(.system(size: 11, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .frame(width: 17, height: 17)
                        .background(Circle().fill(Theme.brandGradient))
                        .offset(x: 3, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}

/// 하트 소진 시 타일 영역을 대신하는 안내 카드.
private struct OutOfHeartsCard: View {
    var model: AppModel

    var body: some View {
        VStack(spacing: 14) {
            BrokenHeartIcon(size: 56)
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
                Label("Watch an ad to refill a heart", systemImage: "play.rectangle.fill")
            }
            .buttonStyle(ProminentButtonStyle())
            .disabled(!model.ads.rewardedReady)
            .opacity(model.ads.rewardedReady ? 1 : 0.5)
            Text("Hearts refill every 10 minutes.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .harusemCard()
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
                .frame(maxWidth: .infinity, minHeight: 74)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isSelected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.surface))
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.hairline))
                        .shadow(color: isSelected ? Theme.brand.opacity(0.35) : .black.opacity(0.05),
                                radius: isSelected ? 9 : 5, y: 3)
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .scaleEffect(isSelected ? 1.04 : 1)
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct OperatorRow: View {
    var model: AppModel

    /// 연산자별 고유 색 (알록달록 테마).
    private func gradient(for op: Op) -> LinearGradient {
        switch op {
        case .add: Theme.greenGradient
        case .subtract: Theme.tealGradient
        case .multiply: Theme.flameGradient
        case .divide: Theme.purpleGradient
        }
    }

    private func color(for op: Op) -> Color {
        switch op {
        case .add: Theme.success
        case .subtract: Theme.teal
        case .multiply: Theme.flame
        case .divide: Theme.purple
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ForEach(Op.allCases, id: \.self) { op in
                let isSelected = model.selection.op == op
                Button {
                    model.tapOp(op)
                } label: {
                    Text(op.rawValue)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isSelected ? AnyShapeStyle(gradient(for: op)) : AnyShapeStyle(Theme.surface))
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(isSelected ? AnyShapeStyle(Theme.hairline)
                                                             : AnyShapeStyle(color(for: op).opacity(0.35))))
                                .shadow(color: isSelected ? color(for: op).opacity(0.4) : .black.opacity(0.04),
                                        radius: isSelected ? 8 : 4, y: 3)
                        )
                        .foregroundStyle(isSelected ? Color.white : color(for: op))
                }
                .buttonStyle(.plain)
                .animation(.spring(duration: 0.25), value: isSelected)
                .accessibilityLabel(op.accessibilityName)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
    }
}
