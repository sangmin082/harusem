/// 하루 5문제 진행 흐름: 현재 문제, 별점 확정, 총점, 공유 텍스트, 진행 저장/복원.
/// 저장소(UserDefaults 등)는 앱의 몫이고 여기는 Codable 스냅샷만 제공한다.
public struct DailySession: Equatable, Sendable {
    public let daily: DailyPuzzles
    /// 확정된 문제별 별점 (0~3). 미확정은 nil.
    public private(set) var stars: [Int?]
    /// 0~4 = 진행 중인 문제, puzzles.count = 하루 완료.
    public private(set) var currentIndex: Int
    public private(set) var game: GameState

    public init(daily: DailyPuzzles) {
        self.daily = daily
        self.stars = Array(repeating: nil, count: daily.puzzles.count)
        self.currentIndex = 0
        self.game = GameState(puzzle: daily.puzzles[0])
    }

    // MARK: - 조회

    public var isDayComplete: Bool { currentIndex >= daily.puzzles.count }
    public var currentPuzzle: Puzzle { daily.puzzles[min(currentIndex, daily.puzzles.count - 1)] }
    public var totalStars: Int { stars.compactMap { $0 }.reduce(0, +) }
    public var maxStars: Int { daily.puzzles.count * 3 }

    /// 결과 공유용 텍스트 (언어 중립).
    /// 예: "하루셈 2026-07-04 12/15" + 문제별 ★★☆ 그리드.
    public func shareText() -> String {
        var lines = ["하루셈 \(daily.dateKey) \(totalStars)/\(maxStars)"]
        for earned in stars {
            let n = earned ?? 0
            lines.append(String(repeating: "★", count: n) + String(repeating: "☆", count: 3 - n))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - 진행

    @discardableResult
    public mutating func merge(lhsID: Int, op: Op, rhsID: Int) throws -> GameState.Tile {
        precondition(!isDayComplete)
        return try game.merge(lhsID: lhsID, op: op, rhsID: rhsID)
    }

    /// 선택 상태 머신을 통한 타일 탭 (game이 private(set)이라 여기서 중계한다).
    @discardableResult
    public mutating func tapTile(_ id: Int, selection: inout TileSelection) -> TileSelection.TapResult {
        guard !isDayComplete else { return .ignored }
        return selection.tapTile(id, state: &game)
    }

    @discardableResult
    public mutating func undo() -> Bool {
        guard !isDayComplete else { return false }
        return game.undo()
    }

    public mutating func reset() {
        guard !isDayComplete else { return }
        game.reset()
    }

    /// 현재 문제의 별점을 확정하고 다음 문제로 넘어간다.
    /// 목표 정확 도달 시 3별, 아니면 현재 가장 가까운 값 기준 (0별 가능).
    @discardableResult
    public mutating func submitCurrent() -> Int {
        precondition(!isDayComplete)
        let earned = game.starRating
        stars[currentIndex] = earned
        currentIndex += 1
        if !isDayComplete {
            game = GameState(puzzle: daily.puzzles[currentIndex])
        }
        return earned
    }

    // MARK: - 저장/복원

    public struct MoveRecord: Codable, Equatable, Sendable {
        public let lhsID: Int
        public let op: Op
        public let rhsID: Int

        public init(_ move: GameState.Move) {
            self.lhsID = move.lhs.id
            self.op = move.op
            self.rhsID = move.rhs.id
        }
    }

    public struct Snapshot: Codable, Equatable, Sendable {
        public let dateKey: String
        public let generatorVersion: Int
        public let stars: [Int?]
        public let currentIndex: Int
        /// 진행 중인 문제의 이동 기록 (완료된 문제는 별점만 남긴다).
        public let currentMoves: [MoveRecord]
    }

    public var snapshot: Snapshot {
        Snapshot(
            dateKey: daily.dateKey,
            generatorVersion: daily.generatorVersion,
            stars: stars,
            currentIndex: currentIndex,
            currentMoves: isDayComplete ? [] : game.moves.map(MoveRecord.init)
        )
    }

    /// 스냅샷 복원. 날짜/버전 불일치, 범위 오류, 이동 재생 실패 시 nil (새 세션으로 시작).
    public init?(daily: DailyPuzzles, snapshot: Snapshot) {
        let count = daily.puzzles.count
        guard snapshot.dateKey == daily.dateKey,
              snapshot.generatorVersion == daily.generatorVersion,
              snapshot.stars.count == count,
              (0...count).contains(snapshot.currentIndex),
              snapshot.stars.prefix(snapshot.currentIndex).allSatisfy({ $0 != nil }),
              snapshot.stars.dropFirst(snapshot.currentIndex).allSatisfy({ $0 == nil }),
              snapshot.stars.allSatisfy({ $0 == nil || (0...3).contains($0!) })
        else { return nil }

        self.daily = daily
        self.stars = snapshot.stars
        self.currentIndex = snapshot.currentIndex

        var game = GameState(puzzle: daily.puzzles[min(snapshot.currentIndex, count - 1)])
        if snapshot.currentIndex < count {
            for record in snapshot.currentMoves {
                guard game.canMerge(lhsID: record.lhsID, op: record.op, rhsID: record.rhsID),
                      (try? game.merge(lhsID: record.lhsID, op: record.op, rhsID: record.rhsID)) != nil
                else { return nil }
            }
        }
        self.game = game
    }
}
