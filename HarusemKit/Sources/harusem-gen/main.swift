import Foundation
import HarusemKit

// swift run harusem-gen 2026-07-04 → 그날 5문제와 해답 출력

let arguments = CommandLine.arguments
let dateKey: String
if arguments.count >= 2 {
    dateKey = arguments[1]
} else {
    dateKey = PuzzleGenerator.dateKey(for: Date())
    print("(날짜 인자가 없어 오늘 날짜 사용: \(dateKey))\n")
}

do {
    let daily = try PuzzleGenerator().puzzles(for: dateKey)
    print("하루셈 \(daily.dateKey) (생성기 v\(daily.generatorVersion))")
    print(String(repeating: "=", count: 40))

    for (index, puzzle) in daily.puzzles.enumerated() {
        print("""

        [문제 \(index + 1)] 목표: \(puzzle.target)
          숫자: \(puzzle.numbers.map(String.init).joined(separator: " "))
          최소 연산: \(puzzle.minOperations)회 | 해 상태 수: \(puzzle.solutionStateCount) \
        | 난이도 점수: \(puzzle.difficultyScore)
          해답:
        """)
        let result = Solver.solve(numbers: puzzle.numbers, target: puzzle.target)
        for step in result.steps {
            print("    \(step.description)")
        }
    }
} catch GeneratorError.invalidDateKey(let key) {
    FileHandle.standardError.write(Data("잘못된 날짜 형식: \(key) (YYYY-MM-DD 필요)\n".utf8))
    exit(1)
} catch {
    FileHandle.standardError.write(Data("생성 실패: \(error)\n".utf8))
    exit(1)
}
