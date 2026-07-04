/// "YYYY-MM-DD" 키의 순수 달력 연산. Foundation Calendar에 기대지 않는 결정적 정수 계산.
public enum DateKey {
    /// 하루 전 키. 잘못된 키면 nil.
    public static func previous(_ key: String) -> String? {
        guard let (y, m, d) = parse(key) else { return nil }
        if d > 1 { return format(y, m, d - 1) }
        if m > 1 { return format(y, m - 1, daysInMonth(m - 1, of: y)) }
        return format(y - 1, 12, 31)
    }

    static func parse(_ key: String) -> (year: Int, month: Int, day: Int)? {
        guard PuzzleGenerator.isValidDateKey(key) else { return nil }
        let year = Int(key.prefix(4))!
        let month = Int(key.dropFirst(5).prefix(2))!
        let day = Int(key.suffix(2))!
        guard day <= daysInMonth(month, of: year) else { return nil }
        return (year, month, day)
    }

    static func daysInMonth(_ month: Int, of year: Int) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12: return 31
        case 4, 6, 9, 11: return 30
        default:
            let leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
            return leap ? 29 : 28
        }
    }

    private static func format(_ y: Int, _ m: Int, _ d: Int) -> String {
        func pad(_ n: Int, _ width: Int) -> String {
            let s = String(n)
            return String(repeating: "0", count: max(0, width - s.count)) + s
        }
        return "\(pad(y, 4))-\(pad(m, 2))-\(pad(d, 2))"
    }
}

/// 완료한 하루의 기록.
public struct DayRecord: Codable, Equatable, Sendable {
    public let dateKey: String
    public let stars: [Int]

    public init(dateKey: String, stars: [Int]) {
        self.dateKey = dateKey
        self.stars = stars
    }

    public var totalStars: Int { stars.reduce(0, +) }
    public var isPerfect: Bool { !stars.isEmpty && stars.allSatisfy { $0 == 3 } }
}

/// 누적 플레이 기록: 연속 플레이(streak), 총 별, 퍼펙트 데이. 아카이브(마일스톤 4)의 데이터 기반.
public struct PlayerRecords: Codable, Equatable, Sendable {
    /// dateKey 오름차순, 날짜당 하나 (ISO 날짜는 문자열 비교가 시간 순서와 일치).
    public private(set) var days: [DayRecord]

    public init() {
        self.days = []
    }

    /// 하루 기록 추가. 같은 날짜가 있으면 교체 (멱등).
    public mutating func record(_ day: DayRecord) {
        if let index = days.firstIndex(where: { $0.dateKey == day.dateKey }) {
            days[index] = day
            return
        }
        let insertAt = days.firstIndex { $0.dateKey > day.dateKey } ?? days.count
        days.insert(day, at: insertAt)
    }

    public func day(for dateKey: String) -> DayRecord? {
        days.first { $0.dateKey == dateKey }
    }

    public var daysPlayed: Int { days.count }
    public var totalStars: Int { days.reduce(0) { $0 + $1.totalStars } }
    public var perfectDayCount: Int { days.count { $0.isPerfect } }

    /// dateKey에서 끝나는 연속 플레이 일수. 그날 기록이 없으면 0.
    public func streak(endingAt dateKey: String) -> Int {
        let played = Set(days.map(\.dateKey))
        var cursor = dateKey
        var count = 0
        while played.contains(cursor) {
            count += 1
            guard let prev = DateKey.previous(cursor) else { break }
            cursor = prev
        }
        return count
    }
}
