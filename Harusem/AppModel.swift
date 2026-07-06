import Foundation
import Observation
import HarusemKit

/// 엔진과 UI 사이의 브리지 — 레벨(단계) 진행 방식.
/// 레벨 1부터 한 문제씩 클리어(별 1개 이상)하면 다음 레벨이 열린다.
/// 별 3개 만점이 아니면 하트 1개 차감. 진행 상태는 UserDefaults에 저장한다.
@Observable
@MainActor
final class AppModel {
    /// 현재 플레이 중인 레벨의 1문제 세션.
    private(set) var session: DailySession
    private(set) var selection = TileSelection()
    /// 현재 플레이 중인 레벨 번호 (1부터).
    private(set) var level: Int
    /// 해금된 최고 레벨 (= 마지막으로 클리어한 레벨 + 1).
    private(set) var maxLevel: Int
    /// 레벨별 최고 별점 (클리어한 레벨만 기록).
    private(set) var bestStars: [Int: Int]
    /// 날짜별 클리어 수 (스트릭/히트맵용). 키는 "YYYY-MM-DD".
    private(set) var activity: [String: Int]
    let store = StoreService()
    let ads = AdsService()
    /// 무효 병합 피드백 트리거 (.sensoryFeedback 용 카운터).
    private(set) var rejectionCount = 0
    /// 현재 표시 중인 힌트 (병합/undo/리셋 시 사라짐).
    private(set) var currentHint: SolutionStep?
    /// 힌트를 눌렀지만 현재 상태에서 도달 불가한 경우.
    private(set) var hintDeadEnd = false

    /// 하루 무료 힌트 수. 소진 후는 리워드 광고로 충전.
    static let dailyHintAllowance = 3
    /// 전면 광고 주기: N번째 클리어마다 1회.
    static let interstitialEvery = 3

    private let defaults: UserDefaults
    private(set) var heartBank: HeartBank

    private static let levelKey = "harusem.level.playing"
    private static let maxLevelKey = "harusem.level.max"
    private static let starsKey = "harusem.level.beststars"
    private static let activityKey = "harusem.level.activity"
    private static let snapshotKey = "harusem.level.snapshot"
    private static let completionsKey = "harusem.level.completions"
    private static let hintsKey = "harusem.hints.used"
    private static let heartsKey = "harusem.hearts"

    init(defaults: UserDefaults = .standard, now: Date = .now) {
        self.defaults = defaults

        let storedMax = defaults.integer(forKey: Self.maxLevelKey)
        let maxLevel = max(1, storedMax)
        self.maxLevel = maxLevel
        let storedLevel = defaults.integer(forKey: Self.levelKey)
        let level = (1...maxLevel).contains(storedLevel) ? storedLevel : maxLevel
        self.level = level

        if let data = defaults.data(forKey: Self.starsKey),
           let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) {
            self.bestStars = decoded
        } else {
            self.bestStars = [:]
        }
        if let data = defaults.data(forKey: Self.activityKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.activity = decoded
        } else {
            self.activity = [:]
        }

        self.session = Self.loadOrCreateSession(level: level, defaults: defaults)

        if let data = defaults.data(forKey: Self.heartsKey),
           let decoded = try? JSONDecoder().decode(HeartBank.self, from: data) {
            self.heartBank = decoded
        } else {
            self.heartBank = HeartBank(now: now.timeIntervalSince1970)
        }
        refreshHearts(now: now)
    }

    /// 레벨 퍼즐로 1문제 세션 생성. 저장된 진행 스냅샷이 같은 레벨이면 복원한다.
    private static func loadOrCreateSession(level: Int, defaults: UserDefaults?) -> DailySession {
        // 생성기는 결정적이며 레벨 1~50 전수 테스트로 검증됨 — 유효한 레벨에서 실패하지 않는다.
        let puzzle = try! PuzzleGenerator().levelPuzzle(level)
        let daily = DailyPuzzles(
            dateKey: Self.sessionKey(level: level),
            generatorVersion: PuzzleGenerator.version,
            puzzles: [puzzle]
        )
        if let defaults,
           let data = defaults.data(forKey: snapshotKey),
           let snapshot = try? JSONDecoder().decode(DailySession.Snapshot.self, from: data),
           let restored = DailySession(daily: daily, snapshot: snapshot) {
            return restored
        }
        return DailySession(daily: daily)
    }

    private static func sessionKey(level: Int) -> String {
        "level-\(level)"
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

    /// 현재 레벨의 별점을 확정한다.
    /// 별 3개 미만이면 하트 1개 차감. 별 1개 이상이면 클리어 → 다음 레벨 해금.
    func submit(now: Date = .now) {
        guard !session.isDayComplete else { return }
        selection.clear()
        clearHint()
        session.submitCurrent()
        let stars = session.totalStars

        if stars < 3 {
            refreshHearts(now: now)
            heartBank.spend(now: now.timeIntervalSince1970)
            saveHearts()
        }

        if stars >= 1 {
            if (bestStars[level] ?? 0) < stars {
                bestStars[level] = stars
            }
            if level == maxLevel {
                maxLevel = level + 1
            }
            activity[PuzzleGenerator.dateKey(for: now), default: 0] += 1
            saveProgress()

            // 전면 광고: N번째 클리어마다. 결과 화면 전환과 겹치지 않게 잠깐 대기.
            let completions = defaults.integer(forKey: Self.completionsKey) + 1
            defaults.set(completions, forKey: Self.completionsKey)
            if completions % Self.interstitialEvery == 0 {
                let adsRemoved = store.ownsRemoveAds
                Task {
                    try? await Task.sleep(for: .seconds(0.7))
                    ads.showInterstitialAfterDayComplete(adsRemoved: adsRemoved)
                }
            }
        }
        save()
    }

    // MARK: - 레벨 이동

    /// 레벨 목록에서 선택. 진행 중인 현재 레벨을 다시 누르면 이어한다 (리셋하지 않음).
    func openLevel(_ n: Int) {
        guard (1...maxLevel).contains(n) else { return }
        if n == level, !session.isDayComplete { return }
        startLevel(n)
    }

    /// 방금 클리어한 레벨의 다음 레벨로.
    func advanceToNextLevel() {
        guard session.isDayComplete else { return }
        startLevel(min(level + 1, maxLevel))
    }

    /// 현재 레벨 처음부터 다시 (실패 후 재도전 / 클리어 후 다시 플레이).
    func retryLevel() {
        startLevel(level)
    }

    private func startLevel(_ n: Int) {
        selection = TileSelection()
        clearHint()
        level = n
        defaults.set(n, forKey: Self.levelKey)
        session = Self.loadOrCreateSession(level: n, defaults: nil)
        save()
    }

    /// 현재 레벨에서 기록한 최고 별점 (미클리어면 nil).
    var bestStarsForCurrentLevel: Int? {
        bestStars[level]
    }

    /// 클리어한 레벨에서 모은 별 합계.
    var totalStarsEarned: Int {
        bestStars.values.reduce(0, +)
    }

    /// 결과 공유 텍스트. 예: "하루셈 Lv.7 ★★☆ · ⭐️ 18".
    var shareText: String {
        let n = session.isDayComplete ? session.totalStars : 0
        let starLine = String(repeating: "★", count: n) + String(repeating: "☆", count: 3 - n)
        return "하루셈 Lv.\(level) \(starLine) · ⭐️ \(totalStarsEarned)"
    }

    // MARK: - 하트

    var hearts: Int { heartBank.hearts }

    /// 하트가 없어 새 플레이를 시작할 수 없는 상태.
    /// 이미 진행 중인 판(이동 있음)이나 결과 화면은 막지 않는다.
    var needsHeartToPlay: Bool {
        hearts == 0 && !session.isDayComplete && session.game.moves.isEmpty
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

    /// 힌트 예산은 오늘 날짜 기준.
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

    // MARK: - 통계

    /// 연속 플레이 일수 (오늘 또는 어제로 끝나는 스트릭 — 오늘 아직 안 했어도 유지 중으로 본다).
    var currentStreak: Int {
        let today = PuzzleGenerator.dateKey(for: .now)
        var cursor: String? = activity[today] != nil ? today : DateKey.previous(today)
        var count = 0
        while let key = cursor, activity[key] != nil {
            count += 1
            cursor = DateKey.previous(key)
        }
        return count
    }

    /// 클리어한 레벨 수.
    var levelsCleared: Int { bestStars.count }

    /// 별 3개 만점 레벨 수.
    var perfectLevels: Int { bestStars.values.filter { $0 == 3 }.count }

    /// 플레이한 날 수 (클리어 기준).
    var daysPlayed: Int { activity.count }

    struct RecentDay: Identifiable {
        let dateKey: String
        /// 그날 클리어한 레벨 수 (기록 없으면 nil).
        let cleared: Int?
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
            RecentDay(dateKey: key, cleared: activity[key])
        }
    }

    private func saveProgress() {
        defaults.set(maxLevel, forKey: Self.maxLevelKey)
        if let data = try? JSONEncoder().encode(bestStars) {
            defaults.set(data, forKey: Self.starsKey)
        }
        if let data = try? JSONEncoder().encode(activity) {
            defaults.set(data, forKey: Self.activityKey)
        }
    }

    // MARK: - 라이프사이클

    /// 진행 스냅샷 저장 (백그라운드 전환/이동 시).
    func save() {
        if let data = try? JSONEncoder().encode(session.snapshot) {
            defaults.set(data, forKey: Self.snapshotKey)
        }
    }
}
