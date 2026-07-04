// 결정적 퍼즐 생성의 근간.
// Swift의 SystemRandomNumberGenerator / Hasher는 실행마다 시드가 달라지므로 절대 사용하지 않는다.

/// SplitMix64 PRNG. 같은 시드 → 항상 같은 수열 (플랫폼/실행 무관).
public struct SplitMix64: Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// 0..<n 균등 분포. 모듈로 바이어스를 제거하기 위해 리젝션 샘플링.
    public mutating func next(upperBound n: UInt64) -> UInt64 {
        precondition(n > 0)
        let limit = UInt64.max - UInt64.max % n
        while true {
            let x = next()
            if x < limit { return x % n }
        }
    }

    public mutating func int(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound) + 1
        return range.lowerBound + Int(next(upperBound: span))
    }

    /// Fisher–Yates 셔플. 표준 라이브러리 shuffled(using:)은 구현이 바뀔 수 있으므로 직접 구현.
    public mutating func shuffle<T>(_ array: inout [T]) {
        guard array.count > 1 else { return }
        for i in stride(from: array.count - 1, to: 0, by: -1) {
            let j = Int(next(upperBound: UInt64(i + 1)))
            array.swapAt(i, j)
        }
    }

    /// pool에서 중복 없이 k개 추출 (부분 Fisher–Yates).
    public mutating func sample<T>(_ k: Int, from pool: [T]) -> [T] {
        precondition(k <= pool.count)
        var arr = pool
        for i in 0..<k {
            let j = i + Int(next(upperBound: UInt64(arr.count - i)))
            arr.swapAt(i, j)
        }
        return Array(arr.prefix(k))
    }
}

/// FNV-1a 64비트 해시. "YYYY-MM-DD" 문자열을 PRNG 시드로 바꾸는 안정적 해시.
public enum FNV1a {
    public static func hash(_ string: String) -> UInt64 {
        var h: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in string.utf8 {
            h ^= UInt64(byte)
            h &*= 0x0000_0100_0000_01B3
        }
        return h
    }
}
