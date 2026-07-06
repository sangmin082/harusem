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
    let ads = AdsService()
    /// 무효 병합 피드백 트리거 (.sensoryFeedback 용 카운터).
    private(set) var rejectionCount = 0
    /// 아카이브(과거 날짜) 플레이 중인지. 아카이브 진행은 스냅샷 저장하지 않는다.
    private(set) var isArchivePlay = false
    /// 보너스 문제(광고 보고 한 문제 더) 플레이 중인지. 기록/스냅샷에 영향을 주지 않는다.
    private(set) var isBonusPlay = false
    /// 이번 세션 입장 비용을 이미 지불했는지 (다시 플레이 = 하트 선차감).
    /// true면 하트 0이어도 플레이 차단하지 않는다.
    private(set) var entryPaid = false
    /// 현재 표시 중인 힌트 (병합/undo/리셋 시 사라짐).
    private(set) var currentHint: SolutionStep?
    /// 힌트를 눌렀지만 현재 상태에서 도달 불가한 경우.
    private(set) var hintDeadEnd = false

    /// 하루 무료 힌트 수. 소진 후는 리워드 광고 충전 예정 (AdGate.rewardedHintAvailable).
    static let dailyHintAllowance = 3

    private let defaults: UserDefaults
    private(set) var heartBank: HeartBank

    private static let snapshotKey = "harusem.session.snapshot"
    private static let recordsKey = "harusem.records"
    private static let hintsKey = "harusem.hints.used"
    private static let bonusCountKey = "harusem.bonus.count"
    private static let heartsKey = "harusem.hearts"

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
        if let data = defaults.data(forKey: Self.heartsKey),
           let decoded = try? JSONDecoder().decode(HeartBank.self, from: data) {
            self.heartBank = decoded
        } else {
            self.heartBank = HeartBank(now: now.timeIntervalSince1970)
        }
        refreshHearts(now: now)
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
        // 하트 규칙: 별 3개 만점 없이 하루를 끝내면 하트 1개 차감 (보너스 제외)
        if session.isDayComplete, !isBonusPlay, session.totalStars < session.maxStars {
            heartBank.spend(now: Date.now.timeIntervalSince1970)
            saveHearts()
        }
        // 전면 광고는 오늘의 정규 5문제 완료 시에만 (보너스/아카이브 제외).
        // 결과 화면 전환 애니메이션과 겹치지 않게 잠깐 기다렸다 띄운다.
        if session.isDayComplete, !isBonusPlay, !isArchivePlay {
            let adsRemoved = store.ownsRemoveAds
            Task {
                try? await Task.sleep(for: .seconds(0.7))
                ads.showInterstitialAfterDayComplete(adsRemoved: adsRemoved)
            }
        }
        save()
    }

    // MARK: - 보너스 문제 (광고 보고 한 문제 더)

    /// 오늘 몇 번째 보너스 문제인지 (1부터 표시용).
    var currentBonusNumber: Int {
        max(1, bonusCount())
    }

    /// 리워드 광고 시청 완료 → 보너스 문제 시작. 오늘 5문제(또는 이전 보너스) 완료 후에만.
    func startBonusViaAd() {
        guard session.isDayComplete, !isArchivePlay else { return }
        ads.showRewarded { [weak self] in
            self?.enterBonus()
        }
    }

    func exitBonus(now: Date = .now) {
        guard isBonusPlay else { return }
        selection = TileSelection()
        clearHint()
        isBonusPlay = false
        entryPaid = false
        session = Self.loadOrCreateSession(defaults: defaults, now: now)
    }

    private func enterBonus(now: Date = .now) {
        let today = PuzzleGenerator.dateKey(for: now)
        let number = bonusCount(now: now)
        guard let puzzle = try? PuzzleGenerator().bonusPuzzle(for: today, number: number) else { return }
        save()  // 오늘 세션(완료 상태) 먼저 저장
        selection = TileSelection()
        clearHint()
        session = DailySession(daily: DailyPuzzles(
            dateKey: today,
            generatorVersion: PuzzleGenerator.version,
            puzzles: [puzzle]
        ))
        isBonusPlay = true
        defaults.set([today: number + 1], forKey: Self.bonusCountKey)
    }

    /// 날짜별 보너스 순번 (결정적 생성이라 순번을 저장해야 매번 새 문제가 나온다).
    private func bonusCount(now: Date = .now) -> Int {
        let today = PuzzleGenerator.dateKey(for: now)
        guard let stored = defaults.dictionary(forKey: Self.bonusCountKey) as? [String: Int] else { return 0 }
        return stored[today] ?? 0
    }

    // MARK: - 하트

    var hearts: Int { heartBank.hearts }

    /// 하트가 없어 새 플레이를 시작할 수 없는 상태.
    /// 이미 진행 중인 판(이동 있음), 완료된 하루, 보너스(광고 입장), 선차감된 다시 플레이는 막지 않는다.
    var needsHeartToPlay: Bool {
        hearts == 0 && !isBonusPlay && !entryPaid && !session.isDayComplete
            && session.currentIndex == 0 && session.game.moves.isEmpty
    }

    /// 하트 1개를 선차감하고 해당 날짜를 처음부터 다시 플레이한다 (오늘 포함).
    /// 하트가 없거나 잠긴 날짜면 false.
    @discardableResult
    func replay(dateKey: String) -> Bool {
        let today = PuzzleGenerator.dateKey(for: .now)
        guard dateKey == today || (dateKey < today && !isArchiveLocked(dateKey)) else { return false }
        guard let daily = try? PuzzleGenerator().puzzles(for: dateKey) else { return false }
        refreshHearts()
        guard heartBank.spend(now: Date.now.timeIntervalSince1970) else { return false }
        saveHearts()

        selection = TileSelection()
        clearHint()
        isBonusPlay = false
        isArchivePlay = dateKey != today
        entryPaid = true
        session = DailySession(daily: daily)
        save()  // 오늘이면 새 진행 스냅샷으로 교체
        return true
    }

    /// 다음 하트까지 남은 시간 "M:SS" (가득이면 nil). 뷰의 1초 틱(TimelineView)과 함께 쓴다.
    func nextHeartCountdown(now: Date = .now) -> String? {
        guard let seconds = heartBank.nextRegenIn(now: now.timeIntervalSince1970) else { return nil }
        let s = max(0, Int(seconds.rounded(.up)))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    /// 경과 시간만큼 하트 자동 충전 (타이머/앱 활성화 시 호출).
    func refreshHearts(now: Date = .now) {
        let before = heartBank
        heartBank.refresh(now: now.timeIntervalSince1970)
        if heartBank != before { saveHearts() }
    }

    /// 리워드 광고 시청 완료 → 하트 1개 충전.
    func refillHeartViaAd() {
        guard hearts < HeartBank.capacity else { return }
        ads.showRewarded { [weak self] in
            guard let self else { return }
            self.heartBank.refill(now: Date.now.timeIntervalSince1970)
            self.saveHearts()
        }
    }

    private func saveHearts() {
        if let data = try? JSONEncoder().encode(heartBank) {
            defaults.set(data, forKey: Self.heartsKey)
        }
    }

    // MARK: - 힌트

    var hintsRemaining: Int {
        max(0, Self.dailyHintAllowance - hintsUsedToday())
    }

    /// 현재 상태에서 다음 한 수를 보여준다. 도달 불가면 힌트를 소진하지 않는다.
    func useHint() {
        guard !session.isDayComplete, !session.game.isSolved else { return }
        hintDeadEnd = false
        guard hintsRemaining > 0 else { return }
        let tiles = session.game.tiles.map(\.value)
        if let step = Solver.hint(tiles: tiles, target: session.currentPuzzle.target) {
            currentHint = step
            incrementHintsUsed()
        } else {
            hintDeadEnd = true
        }
    }

    /// 힌트 소진 시: 리워드 광고 시청 완료 → 힌트 1개 충전 후 바로 표시.
    func earnHintFromAd() {
        guard hintsRemaining == 0, !session.isDayComplete, !session.game.isSolved else { return }
        ads.showRewarded { [weak self] in
            guard let self else { return }
            self.grantBonusHint()
            self.useHint()
        }
    }

    private func grantBonusHint(now: Date = .now) {
        let today = PuzzleGenerator.dateKey(for: now)
        defaults.set([today: max(0, hintsUsedToday(now: now) - 1)], forKey: Self.hintsKey)
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
        isBonusPlay = false  // 보너스 플레이 중 캘린더로 진입하는 경로 정리
        entryPaid = false  // 첫 도전은 무료 시작 (완료 시 규칙으로만 차감)
    }

    /// 아카이브에서 나와 오늘 세션으로 복귀.
    func exitArchive(now: Date = .now) {
        guard isArchivePlay else { return }
        selection = TileSelection()
        clearHint()
        isArchivePlay = false
        entryPaid = false
        session = Self.loadOrCreateSession(defaults: defaults, now: now)
    }

    private func todayKey(now: Date = .now) -> String {
        isArchivePlay ? PuzzleGenerator.dateKey(for: now) : session.daily.dateKey
    }

    /// 오늘 세션 기준 연속 플레이 일수.
    var currentStreak: Int {
        records.streak(endingAt: session.daily.dateKey)
    }

    /// 공유 텍스트 (스트릭이 2일 이상이면 🔥 라인 추가).
    var shareTextWithStreak: String {
        let base = session.shareText()
        let streak = currentStreak
        return streak > 1 ? base + "\n🔥 \(streak)일 연속" : base
    }

    struct RecentDay: Identifiable {
        let dateKey: String
        /// 그날 획득한 총 별 (기록 없으면 nil).
        let stars: Int?
        var id: String { dateKey }
    }

    /// 오늘 포함 최근 N일 기록 (통계 히트맵용, 과거 → 오늘 순).
    func recentDays(_ count: Int, now: Date = .now) -> [RecentDay] {
        var keys: [String] = []
        var cursor: String? = PuzzleGenerator.dateKey(for: now)
        for _ in 0..<count {
            guard let key = cursor else { break }
            keys.append(key)
            cursor = DateKey.previous(key)
        }
        return keys.reversed().map { key in
            RecentDay(dateKey: key, stars: records.day(for: key)?.totalStars)
        }
    }

    private func recordDayIfComplete() {
        // 보너스 문제는 기록에 반영하지 않는다 (오늘 기록을 1문제 세션이 덮어쓰면 안 됨)
        guard session.isDayComplete, !isBonusPlay else { return }
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
        guard !isArchivePlay, !isBonusPlay,
              PuzzleGenerator.dateKey(for: now) != session.daily.dateKey
        else { return }
        selection = TileSelection()
        clearHint()
        entryPaid = false
        session = Self.loadOrCreateSession(defaults: defaults, now: now)
    }

    /// 오늘 세션만 스냅샷 저장 (아카이브/보너스 진행은 저장하지 않는다).
    func save() {
        guard !isArchivePlay, !isBonusPlay else { return }
        if let data = try? JSONEncoder().encode(session.snapshot) {
            defaults.set(data, forKey: Self.snapshotKey)
        }
    }
}
