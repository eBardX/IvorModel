@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct TempoMapTests {
}

// MARK: -

extension TempoMapTests {
    @Test
    func beatTime_constantTempo60() {
        let tmap = TempoMap()

        #expect(tmap.beatTime(at: WallTime(0)) == BeatTime(0))
        #expect(tmap.beatTime(at: WallTime(2)) == BeatTime(2))
        #expect(tmap.beatTime(at: WallTime(4)) == BeatTime(4))
    }

    @Test
    func defaultTempo() {
        let tmap = TempoMap()

        #expect(tmap.defaultTempo == .default)
    }

    @Test
    func defaultTempo_override() throws {
        let t90  = try #require(Tempo(uintValue: 90))
        let tmap = TempoMap(defaultTempo: t90)

        #expect(tmap.defaultTempo == t90)
    }

    @Test
    func inserting() throws {
        let t120 = try #require(Tempo(uintValue: 120))
        let tmap = TempoMap().inserting(beatTime: BeatTime(1),
                                        tempo: t120)

        #expect(!tmap.isEmpty)
        #expect(tmap[BeatTime(1)] == t120)
    }

    @Test
    func isEmpty() {
        var tmap = TempoMap()

        #expect(tmap.isEmpty)

        tmap.insert(beatTime: .zero,
                    tempo: .default)

        #expect(!tmap.isEmpty)
    }

    @Test
    func merging() throws {
        let t120 = try #require(Tempo(uintValue: 120))
        let t90  = try #require(Tempo(uintValue: 90))
        let tmap1 = TempoMap().inserting(beatTime: BeatTime(1),
                                         tempo: t120)
        let tmap2 = TempoMap().inserting(beatTime: BeatTime(2),
                                         tempo: t90)
        let merged = tmap1.merging(with: tmap2)

        #expect(merged[BeatTime(1)] == t120)
        #expect(merged[BeatTime(2)] == t90)
    }

    @Test
    func removing() throws {
        let t120 = try #require(Tempo(uintValue: 120))
        let tmap = TempoMap()
            .inserting(beatTime: BeatTime(1),
                       tempo: t120)
            .removing(beatTime: BeatTime(1),
                      tempo: t120)

        #expect(tmap.isEmpty)
    }

    @Test
    func subscript_defaultWhenEmpty() {
        let tmap = TempoMap()

        #expect(tmap[BeatTime(5)] == .default)
    }

    @Test
    func subscript_interpolated() throws {
        let t60      = try #require(Tempo(uintValue: 60))
        let t120     = try #require(Tempo(uintValue: 120))
        let t75      = try #require(Tempo(uintValue: 75))
        let tmap = TempoMap()
            .inserting(beatTime: BeatTime(0),
                       tempo: t60)
            .inserting(beatTime: BeatTime(2),
                       tempo: t120)

        // Polynomial n=2: T(u) = T₀ + (T₁−T₀)·u²
        // At u=0.5: 60 + (120−60)·0.25 = 75
        #expect(tmap[BeatTime(1)] == t75)
    }

    @Test
    func wallTime_constantTempo120() throws {
        let t120 = try #require(Tempo(uintValue: 120))
        let tmap = TempoMap().inserting(beatTime: .zero,
                                        tempo: t120)

        #expect(tmap.wallTime(at: BeatTime(0)) == WallTime(0))
        #expect(tmap.wallTime(at: BeatTime(2)) == WallTime(1))
        #expect(tmap.wallTime(at: BeatTime(4)) == WallTime(2))
    }

    @Test
    func wallTime_constantTempo60() {
        let tmap = TempoMap()

        #expect(tmap.wallTime(at: BeatTime(0)) == WallTime(0))
        #expect(tmap.wallTime(at: BeatTime(2)) == WallTime(2))
        #expect(tmap.wallTime(at: BeatTime(4)) == WallTime(4))
    }
}
