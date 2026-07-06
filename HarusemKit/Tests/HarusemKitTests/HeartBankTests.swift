import Foundation
import Testing
@testable import HarusemKit

@Suite("HeartBank")
struct HeartBankTests {
    private let t0 = 1_000_000.0
    private var interval: Double { HeartBank.regenInterval }
    private var cap: Int { HeartBank.capacity }

    @Test("정책 상수: 최대 10개, 10분 충전")
    func policyConstants() {
        #expect(HeartBank.capacity == 10)
        #expect(HeartBank.regenInterval == 600)
    }

    @Test("새 유저는 하트 가득으로 시작")
    func startsFull() {
        let bank = HeartBank(now: t0)
        #expect(bank.hearts == cap)
        #expect(bank.nextRegenIn(now: t0) == nil)
    }

    @Test("소비하면 줄고, interval마다 1개씩 충전된다")
    func spendAndRegen() {
        var bank = HeartBank(now: t0)
        let s1 = bank.spend(now: t0)
        #expect(s1)
        #expect(bank.hearts == cap - 1)

        // interval 직전: 아직 충전 안 됨
        bank.refresh(now: t0 + interval - 1)
        #expect(bank.hearts == cap - 1)
        #expect(bank.nextRegenIn(now: t0 + interval - 1) == 1)

        // interval 경과: 1개 충전 → 가득
        bank.refresh(now: t0 + interval)
        #expect(bank.hearts == cap)
        #expect(bank.nextRegenIn(now: t0 + interval) == nil)
    }

    @Test("여러 interval 경과 시 한꺼번에 충전, 최대 개수 캡")
    func multiRegenCapped() {
        var bank = HeartBank(now: t0)
        for _ in 0..<cap { bank.spend(now: t0) }
        #expect(bank.hearts == 0)
        let s2 = bank.spend(now: t0)
        #expect(!s2)  // 0에서 소비 불가

        // interval × 3 → 3개
        bank.refresh(now: t0 + 3 * interval)
        #expect(bank.hearts == 3)

        // 아주 오래 지나도 캡
        bank.refresh(now: t0 + 100 * interval)
        #expect(bank.hearts == cap)
    }

    @Test("부분 진행 보존: 1.5 interval 경과 후 1개 충전, 다음 하트까지 0.5 interval")
    func partialProgressPreserved() {
        var bank = HeartBank(now: t0)
        bank.spend(now: t0)
        bank.spend(now: t0)
        #expect(bank.hearts == cap - 2)

        bank.refresh(now: t0 + 1.5 * interval)
        #expect(bank.hearts == cap - 1)
        #expect(bank.nextRegenIn(now: t0 + 1.5 * interval) == 0.5 * interval)
    }

    @Test("가득 찬 상태로 오래 있어도 소비 직후 충전 타이머는 그때부터 시작")
    func fullIdleDoesNotBankTime() {
        var bank = HeartBank(now: t0)
        // 가득 상태로 오래 방치 후 소비
        bank.refresh(now: t0 + 6 * interval)
        let s3 = bank.spend(now: t0 + 6 * interval)
        #expect(s3)
        #expect(bank.hearts == cap - 1)
        // 방치 시간은 적립되지 않는다 — 소비 시점부터 interval
        #expect(bank.nextRegenIn(now: t0 + 6 * interval) == interval)
    }

    @Test("광고 충전: 1개 추가, 가득이면 무시")
    func adRefill() {
        var bank = HeartBank(now: t0)
        bank.refill(now: t0)
        #expect(bank.hearts == cap)  // 가득이면 무시

        for _ in 0..<3 { bank.spend(now: t0) }
        bank.refill(now: t0)
        #expect(bank.hearts == cap - 2)
    }

    @Test("Codable 라운드트립")
    func codable() throws {
        var bank = HeartBank(now: t0)
        bank.spend(now: t0)
        let data = try JSONEncoder().encode(bank)
        let decoded = try JSONDecoder().decode(HeartBank.self, from: data)
        #expect(decoded == bank)
    }

    @Test("구버전(최대 5개) 저장분 마이그레이션: 시간이 지나면 10개까지 충전된다")
    func migratesFromSmallerCapacity() throws {
        // 구버전에서 hearts=5로 저장된 JSON을 그대로 디코드
        let legacy = #"{"hearts":5,"regenBase":1000000}"#
        var bank = try JSONDecoder().decode(HeartBank.self, from: Data(legacy.utf8))
        #expect(bank.hearts == 5)
        bank.refresh(now: t0 + 5 * interval)
        #expect(bank.hearts == 10)
    }
}
