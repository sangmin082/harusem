import Testing
@testable import HarusemKit

@Suite("DailySession")
struct DailySessionTests {
    private func makeSession() throws -> DailySession {
        DailySession(daily: try PuzzleGenerator().puzzles(for: "2026-07-04"))
    }

    /// solver의 해답 스텝을 그대로 재생해서 현재 문제를 정확히 푼다.
    private func solveCurrent(_ session: inout DailySession) throws {
        let puzzle = session.currentPuzzle
        let result = Solver.solve(numbers: puzzle.numbers, target: puzzle.target)
        #expect(result.isSolvable)
        for step in result.steps {
            let lhs = session.game.tiles.first { $0.value == step.lhs }!
            let rhs = session.game.tiles.first { $0.value == step.rhs && $0.id != lhs.id }!
            try session.merge(lhsID: lhs.id, op: step.op, rhsID: rhs.id)
        }
        #expect(session.game.isSolved)
    }

    @Test("5문제 전부 정확히 풀면 15/15")
    func perfectDay() throws {
        var session = try makeSession()
        for index in 0..<5 {
            #expect(session.currentIndex == index)
            #expect(!session.isDayComplete)
            try solveCurrent(&session)
            let earned = session.submitCurrent()
            #expect(earned == 3)
        }
        #expect(session.isDayComplete)
        #expect(session.totalStars == 15)
        #expect(session.stars.allSatisfy { $0 == 3 })
    }

    @Test("부분 점수: 목표 근처에서 제출하면 오차 기준 별점 확정")
    func partialCredit() throws {
        var session = try makeSession()
        // 아무것도 안 하고 제출 → 초기 타일 중 가장 가까운 값 기준
        let expected = GameState.stars(target: session.currentPuzzle.target,
                                       achieved: session.game.closestValue)
        let earned = session.submitCurrent()
        #expect(earned == expected)
        #expect(session.stars[0] == earned)
        #expect(session.currentIndex == 1)
        #expect(session.game.puzzle == session.daily.puzzles[1])  // 다음 문제 로드
    }

    @Test("공유 텍스트 형식")
    func shareTextFormat() throws {
        var session = try makeSession()
        try solveCurrent(&session)
        session.submitCurrent()
        for _ in 1..<5 { session.submitCurrent() }  // 나머지는 그대로 제출

        let text = session.shareText()
        let lines = text.split(separator: "\n").map(String.init)
        #expect(lines.count == 6)
        #expect(lines[0].hasPrefix("하루셈 2026-07-04 "))
        #expect(lines[0].hasSuffix("/15"))
        #expect(lines[1] == "★★★")
        for line in lines.dropFirst() {
            #expect(line.count == 3)
            #expect(line.allSatisfy { $0 == "★" || $0 == "☆" })
        }
    }

    @Test("스냅샷 라운드트립: 진행 중 이동까지 복원된다")
    func snapshotRoundTrip() throws {
        var session = try makeSession()
        try solveCurrent(&session)
        session.submitCurrent()

        // 2번 문제 진행 중 상태 만들기 (유효한 병합 하나 수행)
        let tiles = session.game.tiles
        var merged = false
        outer: for a in tiles {
            for b in tiles where a.id != b.id {
                if session.game.canMerge(lhsID: a.id, op: .add, rhsID: b.id) {
                    try session.merge(lhsID: a.id, op: .add, rhsID: b.id)
                    merged = true
                    break outer
                }
            }
        }
        #expect(merged)

        let restored = DailySession(daily: session.daily, snapshot: session.snapshot)
        #expect(restored == session)
    }

    @Test("완료된 하루의 스냅샷 라운드트립")
    func snapshotCompletedDay() throws {
        var session = try makeSession()
        for _ in 0..<5 { session.submitCurrent() }
        #expect(session.isDayComplete)

        let restored = DailySession(daily: session.daily, snapshot: session.snapshot)
        #expect(restored != nil)
        #expect(restored?.isDayComplete == true)
        #expect(restored?.stars == session.stars)
    }

    @Test("손상되거나 안 맞는 스냅샷은 nil → 새 세션으로 시작")
    func invalidSnapshots() throws {
        let daily = try PuzzleGenerator().puzzles(for: "2026-07-04")
        let other = try PuzzleGenerator().puzzles(for: "2026-07-05")
        let good = DailySession(daily: daily).snapshot

        // 다른 날짜의 데일리에 복원 시도
        #expect(DailySession(daily: other, snapshot: good) == nil)

        // 잘못된 이동 기록
        let badMoves = DailySession.Snapshot(
            dateKey: daily.dateKey, generatorVersion: daily.generatorVersion,
            stars: [nil, nil, nil, nil, nil], currentIndex: 0,
            currentMoves: [.init(GameState.Move(
                lhs: .init(id: 999, value: 1), op: .add,
                rhs: .init(id: 998, value: 1), merged: .init(id: 997, value: 2)))]
        )
        #expect(DailySession(daily: daily, snapshot: badMoves) == nil)

        // 인덱스/별점 정합성 깨짐 (확정 안 된 문제를 지나침)
        let badStars = DailySession.Snapshot(
            dateKey: daily.dateKey, generatorVersion: daily.generatorVersion,
            stars: [nil, 3, nil, nil, nil], currentIndex: 2, currentMoves: []
        )
        #expect(DailySession(daily: daily, snapshot: badStars) == nil)

        // 범위 밖 별점
        let outOfRange = DailySession.Snapshot(
            dateKey: daily.dateKey, generatorVersion: daily.generatorVersion,
            stars: [7, nil, nil, nil, nil], currentIndex: 1, currentMoves: []
        )
        #expect(DailySession(daily: daily, snapshot: outOfRange) == nil)
    }

    @Test("완료 후에는 undo/reset이 동작하지 않는다")
    func noMutationAfterComplete() throws {
        var session = try makeSession()
        for _ in 0..<5 { session.submitCurrent() }
        let before = session
        let didUndo = session.undo()
        #expect(!didUndo)
        session.reset()
        #expect(session == before)
    }
}
