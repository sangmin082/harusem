import Testing
@testable import HarusemKit

private func makePuzzle(numbers: [Int] = [2, 3, 5, 7, 11, 25], target: Int = 100) -> Puzzle {
    Puzzle(numbers: numbers, target: target, minOperations: 3, solutionStateCount: 1)
}

@Suite("GameState")
struct GameStateTests {
    @Test("병합하면 타일이 하나 줄고 결과 타일이 생긴다")
    func mergeBasics() throws {
        var state = GameState(puzzle: makePuzzle())
        let merged = try state.merge(lhsID: 5, op: .multiply, rhsID: 0)  // 25 × 2 = 50
        #expect(merged.value == 50)
        #expect(state.tiles.count == 5)
        #expect(state.tiles.contains(merged))
        #expect(state.moves.count == 1)
    }

    @Test("무효 병합은 에러: 음수/분수/자기 자신/없는 타일")
    func invalidMerges() {
        var state = GameState(puzzle: makePuzzle())
        #expect(throws: GameState.MergeError.invalidResult) {
            try state.merge(lhsID: 0, op: .subtract, rhsID: 5)  // 2 - 25 < 0
        }
        #expect(throws: GameState.MergeError.invalidResult) {
            try state.merge(lhsID: 4, op: .divide, rhsID: 0)  // 11 ÷ 2 분수
        }
        #expect(throws: GameState.MergeError.sameTile) {
            try state.merge(lhsID: 0, op: .add, rhsID: 0)
        }
        #expect(throws: GameState.MergeError.tileNotFound) {
            try state.merge(lhsID: 0, op: .add, rhsID: 999)
        }
        #expect(state.tiles.count == 6)
        #expect(state.moves.isEmpty)
        #expect(!state.canMerge(lhsID: 0, op: .subtract, rhsID: 5))
        #expect(state.canMerge(lhsID: 5, op: .subtract, rhsID: 0))
    }

    @Test("목표 도달 판정과 별점")
    func solvedAndStars() throws {
        var state = GameState(puzzle: makePuzzle(numbers: [2, 3, 5, 7, 11, 25], target: 50))
        #expect(!state.isSolved)
        try state.merge(lhsID: 5, op: .multiply, rhsID: 0)  // 25 × 2 = 50
        #expect(state.isSolved)
        #expect(state.starRating == 3)

        #expect(GameState.stars(target: 100, achieved: 100) == 3)
        #expect(GameState.stars(target: 100, achieved: 110) == 2)
        #expect(GameState.stars(target: 100, achieved: 90) == 2)
        #expect(GameState.stars(target: 100, achieved: 125) == 1)
        #expect(GameState.stars(target: 100, achieved: 126) == 0)
    }

    @Test("undo는 직전 상태를 순서까지 정확히 복원한다")
    func undoRestores() throws {
        var state = GameState(puzzle: makePuzzle())
        let before = state
        try state.merge(lhsID: 1, op: .add, rhsID: 3)
        #expect(state != before)
        let didUndo = state.undo()
        #expect(didUndo)
        #expect(state == before)
        let didUndoAgain = state.undo()
        #expect(!didUndoAgain)  // 더 되돌릴 것 없음
    }

    @Test("reset은 초기 상태로 되돌린다")
    func resetRestores() throws {
        var state = GameState(puzzle: makePuzzle())
        let initial = state
        try state.merge(lhsID: 0, op: .add, rhsID: 1)
        try state.merge(lhsID: 6, op: .multiply, rhsID: 2)
        state.reset()
        #expect(state == initial)
    }

    @Test("프로퍼티: 임의의 병합/undo 시퀀스에서 불변 조건 유지")
    func propertyMergeUndoSequences() throws {
        let puzzle = makePuzzle(numbers: [2, 3, 5, 7, 11, 25], target: 100)

        for seed in 0..<200 {
            var rng = SplitMix64(seed: UInt64(seed))
            var state = GameState(puzzle: puzzle)
            var snapshots: [GameState] = [state]  // 스냅샷 스택으로 undo 정합성 검증

            for _ in 0..<40 {
                let action = rng.int(in: 0...9)
                if action < 6, state.tiles.count >= 2 {
                    // 임의의 유효한 병합 시도
                    let i = rng.int(in: 0...(state.tiles.count - 1))
                    var j = rng.int(in: 0...(state.tiles.count - 1))
                    if i == j { j = (j + 1) % state.tiles.count }
                    let op = Op.allCases[rng.int(in: 0...3)]
                    let lhs = state.tiles[i]
                    let rhs = state.tiles[j]

                    if state.canMerge(lhsID: lhs.id, op: op, rhsID: rhs.id) {
                        let countBefore = state.tiles.count
                        let merged = try state.merge(lhsID: lhs.id, op: op, rhsID: rhs.id)
                        #expect(state.tiles.count == countBefore - 1)
                        #expect(merged.value > 0)
                        #expect(op.apply(lhs.value, rhs.value) == merged.value)
                        snapshots.append(state)
                    } else {
                        let before = state
                        #expect(throws: (any Error).self) {
                            try state.merge(lhsID: lhs.id, op: op, rhsID: rhs.id)
                        }
                        #expect(state == before)  // 실패한 병합은 상태를 바꾸지 않는다
                    }
                } else if action < 9 {
                    let expectUndo = snapshots.count > 1
                    let didUndo = state.undo()
                    #expect(didUndo == expectUndo)
                    if expectUndo { snapshots.removeLast() }
                    #expect(state == snapshots.last!)
                } else {
                    state.reset()
                    snapshots = [snapshots.first!]
                    #expect(state == snapshots[0])
                }

                // 공통 불변 조건
                #expect((1...6).contains(state.tiles.count))
                #expect(state.tiles.allSatisfy { $0.value > 0 })
                #expect(Set(state.tiles.map(\.id)).count == state.tiles.count)
                #expect(state.moves.count == 6 - state.tiles.count)
                #expect(state.moves.count == snapshots.count - 1)
            }
        }
    }
}
