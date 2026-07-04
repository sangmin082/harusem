import Foundation
import Observation
import HarusemKit

/// 엔진(DailySession/TileSelection)과 UI 사이의 브리지.
/// 진행 상태는 스냅샷(Codable)으로 UserDefaults에 저장한다.
@Observable
@MainActor
final class AppModel {
    private(set) var session: DailySession
    private(set) var selection = TileSelection()
    private(set) var records: PlayerRecords
    /// 무효 병합 피드백 트리거 (.sensoryFeedback 용 카운터).
    private(set) var rejectionCount = 0

    private let defaults: UserDefaults
    private static let snapshotKey = "harusem.session.snapshot"
    private static let recordsKey = "harusem.records"

    init(defaults: UserDefaults = .standard, now: Date = .now) {
        self.defaults = defaults
        self.session = Self.loadOrCreateSession(defaults: defaults, now: now)
        if let data = defaults.data(forKey: Self.recordsKey),
           let decoded = try? JSONDecoder().decode(PlayerRecords.self, from: data) {
            self.records = decoded
        } else {
            self.records = PlayerRecords()
        }
        // 복원된 세션이 이미 완료 상태면 기록 누락을 보정한다 (멱등).
        recordDayIfComplete()
    }

    private static func loadOrCreateSession(defaults: UserDefaults, now: Date) -> DailySession {
        let dateKey = PuzzleGenerator.dateKey(for: now)
        // 생성기는 결정적이며 연속 30일 전수 테스트로 검증됨 — 유효한 날짜 키에서 실패하지 않는다.
        let daily = try! PuzzleGenerator().puzzles(for: dateKey)
        if let data = defaults.data(forKey: snapshotKey),
           let snapshot = try? JSONDecoder().decode(DailySession.Snapshot.self, from: data),
           let restored = DailySession(daily: daily, snapshot: snapshot) {
            return restored
        }
        return DailySession(daily: daily)
    }

    // MARK: - 입력

    func tapTile(_ id: Int) {
        let result = session.tapTile(id, selection: &selection)
        switch result {
        case .rejected:
            rejectionCount += 1
        case .merged:
            save()
        case .selectionChanged, .ignored:
            break
        }
    }

    func tapOp(_ op: Op) {
        guard !session.isDayComplete else { return }
        _ = selection.tapOp(op)
    }

    func undo() {
        selection.clear()
        session.undo()
        save()
    }

    func reset() {
        selection.clear()
        session.reset()
        save()
    }

    /// 현재 문제의 별점을 확정하고 다음 문제로. 마지막 문제였으면 하루 기록을 남긴다.
    func submit() {
        guard !session.isDayComplete else { return }
        selection.clear()
        session.submitCurrent()
        recordDayIfComplete()
        save()
    }

    /// 오늘 세션 기준 연속 플레이 일수.
    var currentStreak: Int {
        records.streak(endingAt: session.daily.dateKey)
    }

    private func recordDayIfComplete() {
        guard session.isDayComplete else { return }
        let stars = session.stars.compactMap { $0 }
        guard stars.count == session.daily.puzzles.count else { return }
        records.record(DayRecord(dateKey: session.daily.dateKey, stars: stars))
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: Self.recordsKey)
        }
    }

    // MARK: - 라이프사이클

    /// 앱이 다시 활성화될 때 날짜가 바뀌었으면 새 하루 세션으로 교체한다.
    func refreshForDateChange(now: Date = .now) {
        guard PuzzleGenerator.dateKey(for: now) != session.daily.dateKey else { return }
        selection = TileSelection()
        session = Self.loadOrCreateSession(defaults: defaults, now: now)
    }

    func save() {
        if let data = try? JSONEncoder().encode(session.snapshot) {
            defaults.set(data, forKey: Self.snapshotKey)
        }
    }
}
