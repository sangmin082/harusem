import Foundation

/// 하루 퍼즐 한 문제.
public struct Puzzle: Equatable, Codable, Sendable {
    public let numbers: [Int]  // 정렬된 6개
    public let target: Int
    public let minOperations: Int
    public let solutionStateCount: Int

    /// 난이도 점수 = f(최소 연산 횟수, 해 개수).
    /// 연산 횟수가 지배적이고, 같은 연산 횟수 안에서는 해가 적을수록 어렵다.
    public var difficultyScore: Double {
        Double(minOperations) * 10_000 - Double(min(solutionStateCount, 9_999))
    }
}

/// 하루치 퍼즐 5문제 (또는 보너스 등 임의 문제 묶음).
public struct DailyPuzzles: Equatable, Codable, Sendable {
    public let dateKey: String
    public let generatorVersion: Int
    public let puzzles: [Puzzle]

    public init(dateKey: String, generatorVersion: Int, puzzles: [Puzzle]) {
        self.dateKey = dateKey
        self.generatorVersion = generatorVersion
        self.puzzles = puzzles
    }
}

public enum GeneratorError: Error, Equatable {
    case invalidDateKey(String)
    case exhausted(dateKey: String)
    case invalidLevel(Int)
}

/// 날짜 기반 결정적 퍼즐 생성기.
///
/// 결정성 규약:
/// - 시드는 "harusem/v{version}/{dateKey}/{round}"의 FNV-1a 해시. 같은 날짜 → 항상 같은 5문제.
/// - 리젝션 샘플링으로 조건(해 존재, 자명한 해 리젝, 난이도 단조 증가)을 만족할 때까지 재생성하되,
///   실패 시 round를 올려 시드를 다시 파생하므로 시드 스트림은 결정성을 유지한다.
/// - 알고리즘이 바뀌면 과거 날짜 퍼즐이 바뀌므로 version을 반드시 올린다.
public struct PuzzleGenerator: Sendable {
    public static let version = 1

    public static let puzzlesPerDay = 5
    static let maxRounds = 64
    static let maxAttemptsPerPuzzle = 60

    /// 문제별 목표값 범위 (1번 50~150 → 5번 300~600).
    static let targetRanges: [ClosedRange<Int>] = [
        50...150, 100...250, 150...350, 220...450, 300...600,
    ]
    /// 문제별 큰 수 풀 (난이도별 조정).
    static let bigPools: [[Int]] = [
        [11, 13, 15, 20, 25],
        [11, 13, 15, 20, 25],
        [11, 13, 15, 20, 25, 30, 50, 75],
        [11, 13, 15, 20, 25, 30, 50, 75],
        [20, 25, 30, 50, 75, 100],
    ]
    /// 문제별 최소 연산 횟수 하한. 2 이하(자명한 해)는 전 문제 공통으로 리젝.
    static let minOperationsFloor = [3, 3, 3, 4, 4]

    public init() {}

    /// dateKey는 유저 로컬 날짜의 "YYYY-MM-DD".
    public func puzzles(for dateKey: String) throws -> DailyPuzzles {
        guard Self.isValidDateKey(dateKey) else {
            throw GeneratorError.invalidDateKey(dateKey)
        }
        for round in 0..<Self.maxRounds {
            var rng = SplitMix64(seed: FNV1a.hash("harusem/v\(Self.version)/\(dateKey)/\(round)"))
            if let puzzles = generateDay(rng: &rng) {
                return DailyPuzzles(dateKey: dateKey, generatorVersion: Self.version, puzzles: puzzles)
            }
        }
        throw GeneratorError.exhausted(dateKey: dateKey)
    }

    /// 하루 5문제 완료 후 "광고 보고 한 문제 더"용 보너스 문제.
    /// 같은 날짜 + 같은 순번(number) → 항상 같은 문제 (결정성 유지).
    /// 난이도는 3~5번 문제 프로필을 순환한다.
    public func bonusPuzzle(for dateKey: String, number: Int) throws -> Puzzle {
        guard Self.isValidDateKey(dateKey) else {
            throw GeneratorError.invalidDateKey(dateKey)
        }
        precondition(number >= 0)
        let profileIndex = 2 + (number % 3)
        for round in 0..<Self.maxRounds {
            var rng = SplitMix64(
                seed: FNV1a.hash("harusem/v\(Self.version)/\(dateKey)/bonus/\(number)/\(round)"))
            if let puzzle = generatePuzzle(index: profileIndex, minScore: -.infinity, rng: &rng) {
                return puzzle
            }
        }
        throw GeneratorError.exhausted(dateKey: dateKey)
    }

    /// 단계(레벨) 진행용 퍼즐. 같은 레벨 번호 → 항상 같은 문제 (결정성 유지).
    ///
    /// 난이도는 3레벨마다 한 단계씩 올라 13레벨부터 최고 프로필로 고정된다
    /// (레벨 1~3 = 프로필 0, 4~6 = 1, 7~9 = 2, 10~12 = 3, 13+ = 4).
    public func levelPuzzle(_ level: Int) throws -> Puzzle {
        guard level >= 1 else { throw GeneratorError.invalidLevel(level) }
        let profileIndex = Self.profileIndex(forLevel: level)
        for round in 0..<Self.maxRounds {
            var rng = SplitMix64(
                seed: FNV1a.hash("harusem/v\(Self.version)/level/\(level)/\(round)"))
            if let puzzle = generatePuzzle(index: profileIndex, minScore: -.infinity, rng: &rng) {
                return puzzle
            }
        }
        throw GeneratorError.exhausted(dateKey: "level/\(level)")
    }

    static func profileIndex(forLevel level: Int) -> Int {
        min(targetRanges.count - 1, (level - 1) / 3)
    }

    /// Date → 유저 로컬 "YYYY-MM-DD" 키.
    public static func dateKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    static func isValidDateKey(_ key: String) -> Bool {
        let bytes = Array(key.utf8)
        guard bytes.count == 10, bytes[4] == UInt8(ascii: "-"), bytes[7] == UInt8(ascii: "-") else {
            return false
        }
        for (i, b) in bytes.enumerated() where i != 4 && i != 7 {
            guard b >= UInt8(ascii: "0") && b <= UInt8(ascii: "9") else { return false }
        }
        guard let month = Int(key.dropFirst(5).prefix(2)), let day = Int(key.suffix(2)) else {
            return false
        }
        return (1...12).contains(month) && (1...31).contains(day)
    }

    private func generateDay(rng: inout SplitMix64) -> [Puzzle]? {
        var puzzles: [Puzzle] = []
        var previousScore = -Double.infinity

        for index in 0..<Self.puzzlesPerDay {
            guard let puzzle = generatePuzzle(index: index, minScore: previousScore, rng: &rng) else {
                return nil
            }
            previousScore = puzzle.difficultyScore
            puzzles.append(puzzle)
        }
        return puzzles
    }

    private func generatePuzzle(index: Int, minScore: Double, rng: inout SplitMix64) -> Puzzle? {
        let targetRange = Self.targetRanges[index]
        let opsFloor = Self.minOperationsFloor[index]

        for _ in 0..<Self.maxAttemptsPerPuzzle {
            let smalls = rng.sample(4, from: Array(1...10))
            let bigs = rng.sample(2, from: Self.bigPools[index])
            let numbers = (smalls + bigs).sorted()

            let analysis = Solver.analyze(numbers)

            // 딕셔너리 순회는 순서가 비결정적이므로 반드시 값 기준으로 정렬한 뒤 고른다.
            var candidates: [Puzzle] = []
            for (value, info) in analysis.values {
                guard targetRange.contains(value),
                      info.minOperations >= opsFloor,
                      !numbers.contains(value)
                else { continue }
                let puzzle = Puzzle(
                    numbers: numbers,
                    target: value,
                    minOperations: info.minOperations,
                    solutionStateCount: info.stateCount
                )
                // 난이도 단조 증가 (엄격).
                guard puzzle.difficultyScore > minScore else { continue }
                candidates.append(puzzle)
            }
            candidates.sort { $0.target < $1.target }

            guard !candidates.isEmpty else { continue }
            return candidates[rng.int(in: 0...(candidates.count - 1))]
        }
        return nil
    }
}
