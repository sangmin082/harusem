/// 하트(플레이 에너지) 은행.
/// - 최대 5개, 30분마다 1개 자동 충전 (지연 계산 — 앱이 꺼져 있어도 시간만큼 쌓인다)
/// - 하루를 별 3개 만점 없이 끝내면 1개 소비, 광고 시청으로 1개 충전
/// 시각(now)을 epoch 초로 주입받으므로 결정적으로 테스트할 수 있다.
public struct HeartBank: Codable, Equatable, Sendable {
    public static let capacity = 5
    public static let regenInterval: Double = 30 * 60

    public private(set) var hearts: Int
    /// 다음 충전 계산의 기준 시각 (epoch 초). 가득 차 있는 동안엔 계속 현재로 밀린다.
    public private(set) var regenBase: Double

    /// 새 유저는 가득 찬 상태로 시작.
    public init(now: Double) {
        self.hearts = Self.capacity
        self.regenBase = now
    }

    /// 경과 시간만큼 하트를 충전한다. 부분 진행(interval 미만)은 보존된다.
    public mutating func refresh(now: Double) {
        guard hearts < Self.capacity else {
            regenBase = now
            return
        }
        guard now > regenBase else { return }
        let gained = Int((now - regenBase) / Self.regenInterval)
        guard gained > 0 else { return }
        hearts = min(Self.capacity, hearts + gained)
        regenBase = hearts == Self.capacity ? now : regenBase + Double(gained) * Self.regenInterval
    }

    /// 다음 하트까지 남은 시간(초). 가득이면 nil.
    public func nextRegenIn(now: Double) -> Double? {
        guard hearts < Self.capacity else { return nil }
        return max(0, Self.regenInterval - (now - regenBase))
    }

    /// 하트 1개 소비. 없으면 false.
    @discardableResult
    public mutating func spend(now: Double) -> Bool {
        refresh(now: now)
        guard hearts > 0 else { return false }
        if hearts == Self.capacity {
            regenBase = now  // 가득에서 처음 소비될 때 충전 타이머 시작
        }
        hearts -= 1
        return true
    }

    /// 하트 1개 충전 (광고 보상 등). 가득이면 무시.
    public mutating func refill(now: Double) {
        refresh(now: now)
        guard hearts < Self.capacity else { return }
        hearts += 1
        if hearts == Self.capacity {
            regenBase = now
        }
    }
}
