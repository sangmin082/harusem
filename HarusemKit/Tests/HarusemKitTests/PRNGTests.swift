import Testing
@testable import HarusemKit

@Suite("SplitMix64 / FNV-1a")
struct PRNGTests {
    @Test("SplitMix64 알려진 수열 스냅샷 (레퍼런스 구현과 일치)")
    func splitMix64KnownSequence() {
        // 시드 1234567의 레퍼런스 출력 (Vigna의 splitmix64.c 기준)
        var rng = SplitMix64(seed: 1_234_567)
        #expect(rng.next() == 6_457_827_717_110_365_317)
        #expect(rng.next() == 3_203_168_211_198_807_973)
        #expect(rng.next() == 9_817_491_932_198_370_423)
    }

    @Test("같은 시드 → 같은 수열")
    func deterministicSequence() {
        var a = SplitMix64(seed: 42)
        var b = SplitMix64(seed: 42)
        for _ in 0..<1_000 {
            #expect(a.next() == b.next())
        }
    }

    @Test("FNV-1a 알려진 해시 스냅샷")
    func fnv1aKnownValues() {
        #expect(FNV1a.hash("") == 0xCBF2_9CE4_8422_2325)
        #expect(FNV1a.hash("a") == 0xAF63_DC4C_8601_EC8C)
        #expect(FNV1a.hash("2026-07-04") == FNV1a.hash("2026-07-04"))
        #expect(FNV1a.hash("2026-07-04") != FNV1a.hash("2026-07-05"))
    }

    @Test("bounded next는 범위 안의 값만 낸다")
    func boundedRange() {
        var rng = SplitMix64(seed: 7)
        for _ in 0..<10_000 {
            let v = rng.int(in: 3...17)
            #expect((3...17).contains(v))
        }
    }

    @Test("sample은 중복 없이 k개를 뽑는다")
    func sampleDistinct() {
        var rng = SplitMix64(seed: 99)
        for _ in 0..<100 {
            let picked = rng.sample(4, from: Array(1...10))
            #expect(picked.count == 4)
            #expect(Set(picked).count == 4)
            #expect(picked.allSatisfy { (1...10).contains($0) })
        }
    }
}
