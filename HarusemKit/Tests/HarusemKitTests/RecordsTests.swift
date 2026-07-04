import Foundation
import Testing
@testable import HarusemKit

@Suite("DateKey")
struct DateKeyTests {
    @Test("하루 전 계산: 월/연/윤년 경계")
    func previousDay() {
        #expect(DateKey.previous("2026-07-04") == "2026-07-03")
        #expect(DateKey.previous("2026-07-01") == "2026-06-30")
        #expect(DateKey.previous("2026-01-01") == "2025-12-31")
        #expect(DateKey.previous("2026-03-01") == "2026-02-28")  // 평년
        #expect(DateKey.previous("2024-03-01") == "2024-02-29")  // 윤년
        #expect(DateKey.previous("2000-03-01") == "2000-02-29")  // 400의 배수는 윤년
        #expect(DateKey.previous("2100-03-01") == "2100-02-28")  // 100의 배수는 평년
        #expect(DateKey.previous("2026-05-01") == "2026-04-30")
    }

    @Test("잘못된 키는 nil")
    func invalidKeys() {
        #expect(DateKey.previous("2026-7-4") == nil)
        #expect(DateKey.previous("2026-02-30") == nil)
        #expect(DateKey.previous("hello") == nil)
    }
}

@Suite("PlayerRecords")
struct PlayerRecordsTests {
    private func day(_ key: String, _ stars: [Int] = [3, 3, 3, 3, 3]) -> DayRecord {
        DayRecord(dateKey: key, stars: stars)
    }

    @Test("기록 추가는 날짜순 정렬 + 같은 날짜는 교체 (멱등)")
    func upsert() {
        var records = PlayerRecords()
        records.record(day("2026-07-02"))
        records.record(day("2026-06-30"))
        records.record(day("2026-07-01", [1, 2, 3, 0, 2]))
        #expect(records.days.map(\.dateKey) == ["2026-06-30", "2026-07-01", "2026-07-02"])

        records.record(day("2026-07-01", [3, 3, 3, 3, 3]))  // 교체
        #expect(records.daysPlayed == 3)
        #expect(records.day(for: "2026-07-01")?.totalStars == 15)
    }

    @Test("집계: 총 별, 퍼펙트 데이")
    func aggregates() {
        var records = PlayerRecords()
        records.record(day("2026-07-01", [3, 3, 3, 3, 3]))
        records.record(day("2026-07-02", [1, 2, 3, 0, 2]))
        #expect(records.totalStars == 15 + 8)
        #expect(records.perfectDayCount == 1)
        #expect(records.day(for: "2026-07-02")?.isPerfect == false)
    }

    @Test("스트릭: 연속이면 증가, 빠진 날이 있으면 끊긴다")
    func streaks() {
        var records = PlayerRecords()
        records.record(day("2026-06-29"))
        records.record(day("2026-06-30"))
        records.record(day("2026-07-01"))
        #expect(records.streak(endingAt: "2026-07-01") == 3)
        #expect(records.streak(endingAt: "2026-06-30") == 2)
        #expect(records.streak(endingAt: "2026-07-02") == 0)  // 그날 기록 없음

        records.record(day("2026-07-03"))  // 07-02가 비어 스트릭 리셋
        #expect(records.streak(endingAt: "2026-07-03") == 1)
    }

    @Test("스트릭이 월/연 경계를 넘는다")
    func streakAcrossBoundaries() {
        var records = PlayerRecords()
        records.record(day("2025-12-30"))
        records.record(day("2025-12-31"))
        records.record(day("2026-01-01"))
        records.record(day("2026-01-02"))
        #expect(records.streak(endingAt: "2026-01-02") == 4)
    }

    @Test("Codable 라운드트립")
    func codableRoundTrip() throws {
        var records = PlayerRecords()
        records.record(day("2026-07-01", [1, 2, 3, 0, 2]))
        records.record(day("2026-07-02"))

        let data = try JSONEncoder().encode(records)
        let decoded = try JSONDecoder().decode(PlayerRecords.self, from: data)
        #expect(decoded == records)
    }
}
