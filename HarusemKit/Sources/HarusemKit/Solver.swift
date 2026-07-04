/// 사칙연산자. 중간 결과 양의 정수 제약을 여기서 강제한다.
public enum Op: String, CaseIterable, Codable, Sendable {
    case add = "+"
    case subtract = "-"
    case multiply = "×"
    case divide = "÷"

    /// a op b. 결과가 양의 정수가 아니면 nil.
    public func apply(_ a: Int, _ b: Int) -> Int? {
        switch self {
        case .add: return a + b
        case .subtract: return a > b ? a - b : nil
        case .multiply: return a * b
        case .divide: return b > 0 && a % b == 0 ? a / b : nil
        }
    }
}

/// 하나의 병합 연산 (해답 표기용). lhs op rhs = result.
public struct SolutionStep: Equatable, Codable, Sendable {
    public let lhs: Int
    public let op: Op
    public let rhs: Int
    public let result: Int

    public var description: String { "\(lhs) \(op.rawValue) \(rhs) = \(result)" }
}

public struct SolverResult: Equatable, Sendable {
    public let isSolvable: Bool
    /// 목표에 도달하는 최소 연산 횟수. 도달 불가면 nil.
    public let minOperations: Int?
    /// 목표값을 포함하는 서로 다른 타일 상태(멀티셋)의 개수. 해의 다양성 지표.
    public let solutionStateCount: Int
    /// 최소 연산 해답 하나.
    public let steps: [SolutionStep]
}

/// 숫자 멀티셋에서 도달 가능한 모든 값의 분석 결과.
/// 상태 = 남은 타일 값의 정렬된 멀티셋. 메모이제이션(방문 집합) 포함 레벨 순 탐색.
public struct Analysis: Sendable {
    public struct ValueInfo: Sendable {
        public let minOperations: Int
        public internal(set) var stateCount: Int
        let witness: [Int]  // 이 값을 처음 포함한 상태 (해답 복원용)
    }

    public let initialNumbers: [Int]
    public let values: [Int: ValueInfo]
    let parents: [[Int]: ([Int], SolutionStep)]

    public func info(for target: Int) -> ValueInfo? { values[target] }
}

public enum Solver {
    /// 숫자 배열(최대 6개)에서 도달 가능한 모든 값을 열거한다.
    /// 중간 결과는 항상 양의 정수 (Op.apply가 보장).
    public static func analyze(_ numbers: [Int]) -> Analysis {
        precondition(!numbers.isEmpty && numbers.count <= 6, "숫자는 1~6개")
        precondition(numbers.allSatisfy { $0 > 0 }, "숫자는 양의 정수")

        let initial = numbers.sorted()
        var visited: Set<[Int]> = [initial]
        var values: [Int: Analysis.ValueInfo] = [:]
        var parents: [[Int]: ([Int], SolutionStep)] = [:]

        func record(_ state: [Int], ops: Int) {
            var seen = Set<Int>()
            for v in state where seen.insert(v).inserted {
                if var info = values[v] {
                    info.stateCount += 1
                    values[v] = info
                } else {
                    values[v] = .init(minOperations: ops, stateCount: 1, witness: state)
                }
            }
        }

        record(initial, ops: 0)
        var current = [initial]
        var ops = 0

        while !current.isEmpty {
            ops += 1
            var next: [[Int]] = []
            for state in current where state.count >= 2 {
                for i in 0..<(state.count - 1) {
                    for j in (i + 1)..<state.count {
                        let x = state[i]  // x <= y (정렬 상태)
                        let y = state[j]
                        for op in Op.allCases {
                            // 정렬된 쌍이므로 큰 값을 왼쪽에 두면 -, ÷의 유효한 순서를 모두 커버한다.
                            guard let r = op.apply(y, x) else { continue }
                            var child = state
                            child.remove(at: j)
                            child.remove(at: i)
                            insertSorted(&child, r)
                            guard visited.insert(child).inserted else { continue }
                            parents[child] = (state, SolutionStep(lhs: y, op: op, rhs: x, result: r))
                            record(child, ops: ops)
                            next.append(child)
                        }
                    }
                }
            }
            current = next
        }

        return Analysis(initialNumbers: initial, values: values, parents: parents)
    }

    /// 목표값 도달 가능 여부 + 최소 연산 횟수 + 해 상태 개수 + 예시 해답.
    public static func solve(numbers: [Int], target: Int) -> SolverResult {
        let analysis = analyze(numbers)
        guard let info = analysis.values[target] else {
            return SolverResult(isSolvable: false, minOperations: nil, solutionStateCount: 0, steps: [])
        }
        var steps: [SolutionStep] = []
        var key = info.witness
        while let (parent, step) = analysis.parents[key] {
            steps.append(step)
            key = parent
        }
        steps.reverse()
        return SolverResult(
            isSolvable: true,
            minOperations: info.minOperations,
            solutionStateCount: info.stateCount,
            steps: steps
        )
    }

    /// 힌트: 현재 남은 타일에서 목표로 가는 최소 해의 다음 한 수.
    /// 이미 도달했거나 여기서는 도달 불가면 nil.
    public static func hint(tiles: [Int], target: Int) -> SolutionStep? {
        guard !tiles.isEmpty, tiles.count <= 6, !tiles.contains(target) else { return nil }
        return solve(numbers: tiles, target: target).steps.first
    }

    private static func insertSorted(_ array: inout [Int], _ value: Int) {
        var lo = 0
        var hi = array.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if array[mid] < value { lo = mid + 1 } else { hi = mid }
        }
        array.insert(value, at: lo)
    }
}
