import Testing
@testable import HarusemKit

/// 연속 dateKey 생성 (테스트 전용, 달력 단순화 없이 직접 계산).
private func consecutiveDateKeys(fromYear year: Int, month: Int, day: Int, count: Int) -> [String] {
    func daysInMonth(_ m: Int, _ y: Int) -> Int {
        switch m {
        case 1, 3, 5, 7, 8, 10, 12: return 31
        case 4, 6, 9, 11: return 30
        default:
            let leap = (y % 4 == 0 && y % 100 != 0) || y % 400 == 0
            return leap ? 29 : 28
        }
    }
    var (y, m, d) = (year, month, day)
    var keys: [String] = []
    for _ in 0..<count {
        keys.append(String(format: "%04d-%02d-%02d", y, m, d))
        d += 1
        if d > daysInMonth(m, y) {
            d = 1
            m += 1
            if m > 12 { m = 1; y += 1 }
        }
    }
    return keys
}

@Suite("PuzzleGenerator")
struct GeneratorTests {
    @Test("결정성: 같은 날짜 100회 생성 → 완전 동일")
    func determinism() throws {
        let generator = PuzzleGenerator()
        let first = try generator.puzzles(for: "2026-07-04")
        for _ in 0..<99 {
            let again = try generator.puzzles(for: "2026-07-04")
            #expect(again == first)
        }
    }

    @Test("다른 날짜 → 다른 퍼즐 (연속 30일 중복 없음)")
    func distinctDays() throws {
        let generator = PuzzleGenerator()
        let keys = consecutiveDateKeys(fromYear: 2026, month: 6, day: 15, count: 30)
        var seen: [[Puzzle]] = []
        for key in keys {
            let daily = try generator.puzzles(for: key)
            #expect(!seen.contains(daily.puzzles), "중복 퍼즐 세트: \(key)")
            seen.append(daily.puzzles)
        }
    }

    @Test("전수 검증: 30일 × 5문제 모두 조건 만족")
    func allPuzzlesValid() throws {
        let generator = PuzzleGenerator()
        let keys = consecutiveDateKeys(fromYear: 2026, month: 7, day: 1, count: 30)
        for key in keys {
            let daily = try generator.puzzles(for: key)
            #expect(daily.generatorVersion == PuzzleGenerator.version)
            #expect(daily.puzzles.count == 5)

            var previousScore = -Double.infinity
            for (index, puzzle) in daily.puzzles.enumerated() {
                // 숫자 구성: 6개, 작은 수 4개 + 큰 수 2개
                #expect(puzzle.numbers.count == 6)
                let smalls = puzzle.numbers.filter { $0 <= 10 }
                #expect(smalls.count == 4, "\(key) 문제\(index + 1): \(puzzle.numbers)")
                #expect(Set(puzzle.numbers).count == 6)

                // 목표값 범위
                #expect(PuzzleGenerator.targetRanges[index].contains(puzzle.target))
                #expect(!puzzle.numbers.contains(puzzle.target))

                // 해 존재 + 자명한 해(2회 이하) 리젝 — solver로 재검증
                let result = Solver.solve(numbers: puzzle.numbers, target: puzzle.target)
                #expect(result.isSolvable, "\(key) 문제\(index + 1) 해 없음")
                #expect(result.minOperations == puzzle.minOperations)
                #expect(result.solutionStateCount == puzzle.solutionStateCount)
                #expect(puzzle.minOperations >= PuzzleGenerator.minOperationsFloor[index])

                // 난이도 단조 증가 (엄격)
                #expect(puzzle.difficultyScore > previousScore,
                        "\(key) 문제\(index + 1) 난이도 역전")
                previousScore = puzzle.difficultyScore
            }
        }
    }

    @Test("잘못된 날짜 형식은 에러")
    func invalidDateKey() {
        let generator = PuzzleGenerator()
        for bad in ["2026-7-4", "20260704", "2026/07/04", "abcd-ef-gh", "2026-13-01", "2026-00-10"] {
            #expect(throws: GeneratorError.invalidDateKey(bad)) {
                try generator.puzzles(for: bad)
            }
        }
    }

    @Test("생성기 버전 필드가 결과에 포함된다")
    func versionField() throws {
        let daily = try PuzzleGenerator().puzzles(for: "2026-01-01")
        #expect(daily.generatorVersion == 1)
    }
}
