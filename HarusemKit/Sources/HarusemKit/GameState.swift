/// 타일 병합 / undo / 리셋을 다루는 상태 머신. 별점 계산 포함. UI를 전혀 모른다.
public struct GameState: Equatable, Sendable {
    public struct Tile: Identifiable, Equatable, Sendable {
        public let id: Int
        public let value: Int
    }

    public struct Move: Equatable, Sendable {
        public let lhs: Tile
        public let op: Op
        public let rhs: Tile
        public let merged: Tile
    }

    public enum MergeError: Error, Equatable {
        case tileNotFound
        case sameTile
        /// 결과가 양의 정수가 아님 (음수/0/분수).
        case invalidResult
    }

    public let puzzle: Puzzle
    public private(set) var tiles: [Tile]
    public private(set) var moves: [Move]

    private let initialTiles: [Tile]
    private var history: [[Tile]]  // 각 병합 직전의 타일 배열 (undo 시 순서까지 정확히 복원)
    private var nextTileID: Int

    public init(puzzle: Puzzle) {
        self.puzzle = puzzle
        self.initialTiles = puzzle.numbers.enumerated().map { Tile(id: $0.offset, value: $0.element) }
        self.tiles = initialTiles
        self.moves = []
        self.history = []
        self.nextTileID = initialTiles.count
    }

    // MARK: - 조회

    public var isSolved: Bool { tiles.contains { $0.value == puzzle.target } }

    /// 목표에 가장 가까운 타일 값.
    public var closestValue: Int {
        tiles.min { abs($0.value - puzzle.target) < abs($1.value - puzzle.target) }!.value
    }

    /// 현재 상태 기준 별점 (0~3).
    public var starRating: Int {
        Self.stars(target: puzzle.target, achieved: closestValue)
    }

    /// 정확히 도달 → 3, 오차 ±10 이내 → 2, ±25 이내 → 1, 그 외 0.
    public static func stars(target: Int, achieved: Int) -> Int {
        switch abs(target - achieved) {
        case 0: return 3
        case 1...10: return 2
        case 11...25: return 1
        default: return 0
        }
    }

    /// UI 차단용: 이 병합이 유효한지 (양의 정수 결과인지) 미리 확인.
    public func canMerge(lhsID: Int, op: Op, rhsID: Int) -> Bool {
        guard lhsID != rhsID,
              let lhs = tiles.first(where: { $0.id == lhsID }),
              let rhs = tiles.first(where: { $0.id == rhsID })
        else { return false }
        return op.apply(lhs.value, rhs.value) != nil
    }

    // MARK: - 상태 전이

    /// 두 타일을 연산자로 병합. 성공 시 새 타일을 반환하고 타일 수가 하나 줄어든다.
    @discardableResult
    public mutating func merge(lhsID: Int, op: Op, rhsID: Int) throws -> Tile {
        guard lhsID != rhsID else { throw MergeError.sameTile }
        guard let lhsIndex = tiles.firstIndex(where: { $0.id == lhsID }),
              let rhsIndex = tiles.firstIndex(where: { $0.id == rhsID })
        else { throw MergeError.tileNotFound }

        let lhs = tiles[lhsIndex]
        let rhs = tiles[rhsIndex]
        guard let value = op.apply(lhs.value, rhs.value) else { throw MergeError.invalidResult }

        let merged = Tile(id: nextTileID, value: value)
        nextTileID += 1

        history.append(tiles)
        // lhs 자리에 병합 결과를 두고 rhs를 제거한다.
        tiles[lhsIndex] = merged
        tiles.remove(at: rhsIndex)
        moves.append(Move(lhs: lhs, op: op, rhs: rhs, merged: merged))
        return merged
    }

    /// 마지막 병합을 되돌린다. undo 무제한. 되돌릴 것이 없으면 false.
    @discardableResult
    public mutating func undo() -> Bool {
        guard let previous = history.popLast() else { return false }
        tiles = previous
        let undone = moves.removeLast()
        nextTileID = undone.merged.id  // 병합 직전의 ID 카운터까지 복원 (undo 후 재병합도 결정적)
        return true
    }

    /// 처음부터 다시하기.
    public mutating func reset() {
        tiles = initialTiles
        moves = []
        history = []
        nextTileID = initialTiles.count
    }
}
