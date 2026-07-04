import Foundation
import Testing
@testable import HarusemKit

@Suite("Solver")
struct SolverTests {
    @Test("알려진 케이스: [1,2,3,4,5,6] → 720 = 2×3×4×5×6 (1은 안 씀), 최소 4회")
    func fullProduct() {
        let result = Solver.solve(numbers: [1, 2, 3, 4, 5, 6], target: 720)
        #expect(result.isSolvable)
        #expect(result.minOperations == 4)
        #expect(result.steps.count == 4)
    }

    @Test("알려진 케이스: [1,2,3] → 9 = (1+2)×3, 최소 2회")
    func smallCase() {
        let result = Solver.solve(numbers: [1, 2, 3], target: 9)
        #expect(result.isSolvable)
        #expect(result.minOperations == 2)
    }

    @Test("이미 갖고 있는 숫자는 0회")
    func zeroOps() {
        let result = Solver.solve(numbers: [1, 2, 3, 4, 5, 6], target: 4)
        #expect(result.isSolvable)
        #expect(result.minOperations == 0)
        #expect(result.steps.isEmpty)
    }

    @Test("도달 불가 케이스: [7,2] → 3")
    func unreachable() {
        // 7+2=9, 7-2=5, 7×2=14, 7÷2 불가 → 3은 도달 불가
        let result = Solver.solve(numbers: [7, 2], target: 3)
        #expect(!result.isSolvable)
        #expect(result.minOperations == nil)
        #expect(result.solutionStateCount == 0)
    }

    @Test("음수 금지: 뺄셈은 큰 수 - 작은 수만 허용")
    func positiveOnlySubtraction() {
        // 3-5는 음수라 차단되지만 5-3=2는 유효
        let result = Solver.solve(numbers: [3, 5], target: 2)
        #expect(result.isSolvable)
        #expect(result.minOperations == 1)
        #expect(Op.subtract.apply(3, 5) == nil)
        #expect(Op.subtract.apply(5, 5) == nil)  // 0도 금지
    }

    @Test("분수 금지: 나누어떨어질 때만 나눗셈 허용")
    func integerOnlyDivision() {
        #expect(Op.divide.apply(7, 2) == nil)
        #expect(Op.divide.apply(8, 2) == 4)
        #expect(Op.divide.apply(5, 5) == 1)
    }

    @Test("중복 숫자 처리: [2,2] → 4")
    func duplicates() {
        let result = Solver.solve(numbers: [2, 2], target: 4)
        #expect(result.isSolvable)
        #expect(result.minOperations == 1)
    }

    @Test("해답 스텝을 재생하면 실제로 목표에 도달한다")
    func stepsReplay() {
        let numbers = [3, 7, 9, 10, 25, 75]
        let target = 337
        let result = Solver.solve(numbers: numbers, target: target)
        guard result.isSolvable else { return }

        var pool = numbers
        for step in result.steps {
            #expect(step.op.apply(step.lhs, step.rhs) == step.result)
            let li = pool.firstIndex(of: step.lhs)
            #expect(li != nil)
            pool.remove(at: li!)
            let ri = pool.firstIndex(of: step.rhs)
            #expect(ri != nil)
            pool.remove(at: ri!)
            pool.append(step.result)
        }
        #expect(pool.contains(target))
    }

    @Test("성능: 6개 숫자 전체 분석이 충분히 빠르다")
    func performance() {
        let start = Date()
        _ = Solver.analyze([7, 8, 9, 10, 75, 100])  // 큰 값 조합 (상태 공간 최대급)
        let elapsed = Date().timeIntervalSince(start)
        // 목표는 수 ms (릴리스 빌드). 디버그+CI 여유를 두고 상한만 검증.
        #expect(elapsed < 2.0)
    }
}
