import Testing
@testable import HarusemKit

private func makeState() -> GameState {
    // 타일: id 0~5 = [2, 3, 5, 7, 11, 25]
    GameState(puzzle: Puzzle(numbers: [2, 3, 5, 7, 11, 25], target: 100,
                             minOperations: 3, solutionStateCount: 1))
}

@Suite("TileSelection")
struct TileSelectionTests {
    @Test("타일 → 연산자 → 타일 → 병합, 결과 타일이 선택 유지된다")
    func basicMergeFlow() {
        var state = makeState()
        var sel = TileSelection()

        let r1 = sel.tapTile(5, state: &state)

        #expect(r1 == .selectionChanged)  // 25
        #expect(sel.lhsID == 5)
        let r2 = sel.tapOp(.multiply)
        #expect(r2 == .selectionChanged)
        #expect(sel.op == .multiply)

        let result = sel.tapTile(0, state: &state)  // 25 × 2 = 50
        guard case .merged(let tile) = result else {
            Issue.record("병합 실패: \(result)")
            return
        }
        #expect(tile.value == 50)
        #expect(state.tiles.count == 5)
        #expect(sel.lhsID == tile.id)  // 연쇄 계산을 위해 결과 타일 선택 유지
        #expect(sel.op == nil)
    }

    @Test("같은 타일 다시 탭 → 선택 해제")
    func deselect() {
        var state = makeState()
        var sel = TileSelection()
        _ = sel.tapTile(2, state: &state)
        let r3 = sel.tapTile(2, state: &state)
        #expect(r3 == .selectionChanged)
        #expect(sel.lhsID == nil)
        #expect(sel.op == nil)
    }

    @Test("연산자 없이 다른 타일 탭 → lhs 교체")
    func replaceLhs() {
        var state = makeState()
        var sel = TileSelection()
        _ = sel.tapTile(0, state: &state)
        let r4 = sel.tapTile(3, state: &state)
        #expect(r4 == .selectionChanged)
        #expect(sel.lhsID == 3)
        #expect(state.tiles.count == 6)  // 병합 없음
    }

    @Test("연산자 토글: 같은 연산자 다시 탭 → 해제, 다른 연산자 → 교체")
    func opToggle() {
        var state = makeState()
        var sel = TileSelection()
        _ = sel.tapTile(0, state: &state)
        _ = sel.tapOp(.add)
        #expect(sel.op == .add)
        _ = sel.tapOp(.divide)
        #expect(sel.op == .divide)
        _ = sel.tapOp(.divide)
        #expect(sel.op == nil)
    }

    @Test("타일 선택 전 연산자 탭은 무시")
    func opWithoutTile() {
        var sel = TileSelection()
        let r5 = sel.tapOp(.add)
        #expect(r5 == .ignored)
        #expect(sel.op == nil)
    }

    @Test("무효 병합은 rejected, 선택은 유지된다")
    func rejectedKeepsSelection() {
        var state = makeState()
        var sel = TileSelection()
        _ = sel.tapTile(0, state: &state)  // 2
        _ = sel.tapOp(.subtract)
        let r6 = sel.tapTile(5, state: &state)
        #expect(r6 == .rejected)  // 2 - 25 음수
        #expect(sel.lhsID == 0)
        #expect(sel.op == .subtract)
        #expect(state.tiles.count == 6)

        // 연산자만 바꾸면 이어서 병합 가능
        _ = sel.tapOp(.multiply)
        guard case .merged(let tile) = sel.tapTile(5, state: &state) else {
            Issue.record("병합 실패")
            return
        }
        #expect(tile.value == 50)
    }

    @Test("존재하지 않는 타일 탭은 무시")
    func unknownTile() {
        var state = makeState()
        var sel = TileSelection()
        let r7 = sel.tapTile(999, state: &state)
        #expect(r7 == .ignored)
        #expect(sel.lhsID == nil)
    }
}
