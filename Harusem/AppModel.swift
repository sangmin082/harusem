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
    let store = StoreService()
    /// 무효 병합 피드백 트리거 (.sensoryFeedback 용 카운터).
    private(set) var rejectionCount = 0
    /// 아카이브(과거 날짜) 플레이 중인지. 아카이브 진행은 스냅샷 저장하지 않는다.
    private(set) var isArchivePlay = false
    /// 현재 표시 중인 힌트 (병합/undo/리셋 시 사라짐).
    private(set) var currentHint: SolutionStep?
    /// 힌트를 눌렀지만 현재 상태에서 도달 불가한 경우.
    private(set) var hintDeadEnd = false

    /// 하루 무료 힌트 수. 소진 후는 리워드 광고 충전 예정 (AdGate.rewardedHintAvailable).
    static let dailyHintAllowance = 3

    private let defaults: UserDefaults
    private static let snapshotKey = "harusem.session.snapshot"
    private static let recordsKey = "harusem.records"
    private static let hintsKey = "harusem.hints.used"

    /// 아카이브 제공 시작일 (서비스 개시일).
    static let archiveEpoch = "2026-07-01"
    /// 아카이브 무료 열람 기간 (최근 N일). 그 이전은 IAP 필요.
    static let freeArchiveDays = 7

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
            clearHint()
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
        clearHint()
        session.undo()
        save()
    }

    func reset() {
        selection.clear()
        clearHint()
        session.reset()
        save()
    }

    /// 현재 문제의 별점을 확정하고 다음 문제로. 마지막 문제였으면 하루 기록을 남긴다.
    func submit() {
        guard !session.isDayComplete else { return }
        selection.clear()
        clearHint()
        session.submitCurrent()
        recordDayIfComplete()
        if session.isDayComplete {
            AdGate.interstitialAfterDayComplete(adsRemoved: store.ownsRemoveAds)
        }
        save()
    }

    // MARK: - 힌트

    var hintsRemaining: Int {
        max(0, Self.dailyHintAllowance - hintsUsedToday())
    }

    /// 현재 상태에서 다음 한 수를 보여준다. 도달 불가면 힌트를 소진하지 않는다.
    func useHint() {
        guard !session.isDayComplete, !session.game.isSolved else { return }
        hintDeadEnd = false
        guard hintsRemaining > 0 else { return }  // TODO: AdGate.rewardedHintAvailable이면 리워드 광고 제안
        let tiles = session.game.tiles.map(\.value)
        if let step = Solver.hint(tiles: tiles, target: session.currentPuzzle.target) {
            currentHint = step
            incrementHintsUsed()
        } else {
            hintDeadEnd = true
        }
    }

    private func clearHint() {
        currentHint = nil
        hintDeadEnd = false
    }

    /// 힌트 예산은 실제 오늘 날짜 기준 (아카이브 플레이도 같은 예산을 쓴다).
    private func hintsUsedToday(now: Date = .now) -> Int {
        let today = PuzzleGenerator.dateKey(for: now)
        guard let stored = defaults.dictionary(forKey: Self.hintsKey) as? [String: Int] else { return 0 }
        return stored[today] ?? 0
    }

    private func incrementHintsUsed(now: Date = .now) {
        let today = PuzzleGenerator.dateKey(for: now)
        // 오늘 카운트만 유지 (지난 날짜 키는 버린다)
        defaults.set([today: hintsUsedToday(now: now) + 1], forKey: Self.hintsKey)
    }

    // MARK: - 아카이브

    /// 오늘 이전(어제 → archiveEpoch) 날짜 목록. 최신순.
    var archiveDateKeys: [String] {
        var keys: [String] = []
        var cursor = DateKey.previous(todayKey())
        while let key = cursor, key >= Self.archiveEpoch {
            keys.append(key)
            cursor = DateKey.previous(key)
        }
        return keys
    }

    /// 무료 열람 범위(최근 N일) 밖이고 아카이브 IAP가 없으면 잠김.
    func isArchiveLocked(_ dateKey: String) -> Bool {
        guard !store.ownsArchive else { return false }
        let free = archiveDateKeys.prefix(Self.freeArchiveDays)
        return !free.contains(dateKey)
    }

    /// 과거 날짜 퍼즐 플레이 시작 (결정적 생성기라 오프라인 재생성 가능).
    func enterArchive(dateKey: String) {
        guard dateKey < todayKey(), !isArchiveLocked(dateKey),
              let daily = try? PuzzleGenerator().puzzles(for: dateKey)
        else { return }
        save()  // 오늘 진행 먼저 저장
        selection = TileSelection()
        clearHint()
        session = DailySession(daily: daily)
        isArchivePlay = true
    }

    /// 아카이브에서 나와 오늘 세션으로 복귀.
    func exitArchive(now: Date = .now) {
        guard isArchivePlay else { return }
        selection = TileSelection()
        clearHint()
        isArchivePlay = false
        session = Self.loadOrCreateSession(defaults: defaults, now: now)
    }

    private func todayKey(now: Date = .now) -> String {
        isArchivePlay ? PuzzleGenerator.dateKey(for: now) : session.daily.dateKey
    }

    /// 오늘 세션 기준 연속 플레이 일수.
    var currentStreak: Int {
        records.streak(endingAt: session.daily.dateKey)
    }

    private func recordDayIfComplete() {
        guard session.isDayComplete else { return }
        let stars = session.stars.compactMap { $0 }
        guard stars.count == session.daily.puzzles.count else { return }
        let newRecord = DayRecord(dateKey: session.daily.dateKey, stars: stars)
        // 아카이브 재도전 등으로 다시 완료해도 최고 기록만 유지한다.
        if let existing = records.day(for: newRecord.dateKey),
           existing.totalStars >= newRecord.totalStars {
            return
        }
        records.record(newRecord)
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: Self.recordsKey)
        }
    }

    // MARK: - 라이프사이클

    /// 앱이 다시 활성화될 때 날짜가 바뀌었으면 새 하루 세션으로 교체한다.
    /// 아카이브 플레이 중이면 그대로 두고, 나갈 때 오늘 세션을 새로 읽는다.
    func refreshForDateChange(now: Date = .now) {
        guard !isArchivePlay,
              PuzzleGenerator.dateKey(for: now) != session.daily.dateKey
        else { return }
        selection = TileSelection()
        clearHint()
        session = Self.loadOrCreateSession(defaults: defaults, now: now)
    }

    /// 오늘 세션만 스냅샷 저장 (아카이브 진행은 저장하지 않는다).
    func save() {
        guard !isArchivePlay else { return }
        if let data = try? JSONEncoder().encode(session.snapshot) {
            defaults.set(data, forKey: Self.snapshotKey)
        }
    }
}
