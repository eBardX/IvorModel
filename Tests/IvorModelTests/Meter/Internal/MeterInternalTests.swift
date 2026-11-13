// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct MeterInternalTests {
}

// MARK: -

extension MeterInternalTests {
    @Test
    func beat_atOffset() throws {
        let beat = try #require(meter("6/8").beat(at: beats(frac(1, 2))))

        #expect(beat.index == 1)
        #expect(beat.length == beats(frac(3, 8)))
        #expect(beat.start == beats(frac(3, 8)))
    }

    @Test
    func beat_atStartOfIrregularBeat() throws {
        let beat = try #require(meter("2+2+3/8").beat(at: beats(frac(1, 2))))

        #expect(beat.index == 2)
        #expect(beat.length == beats(frac(3, 8)))
        #expect(beat.start == beats(frac(1, 2)))
    }

    @Test
    func beat_freeMeter_isNil() {
        #expect(Meter.free.beat(at: .zero) == nil)
    }

    @Test
    func beat_pastEndOfBar_isNil() {
        #expect(meter("6/8").beat(at: beats(frac(3, 4))) == nil)
    }

    @Test
    func beatOffsets() {
        #expect(meter("2+2+3/8").beatOffsets == [.zero, beats(frac(1, 4)), beats(frac(1, 2))])
        #expect(meter("3/4").beatOffsets == [.zero, beats(frac(1, 4)), beats(frac(1, 2))])
    }

    @Test
    func beatOffsets_freeMeter_isEmpty() {
        #expect(Meter.free.beatOffsets.isEmpty)
    }

    @Test
    func floorQuotient() {
        #expect(Meter.floorQuotient(beats(frac(7, 4)), beats(frac(1, 2))) == 3)
        #expect(Meter.floorQuotient(beats(frac(1, 4)), beats(frac(1, 2))) == 0)
        #expect(Meter.floorQuotient(1, beats(frac(1, 2))) == 2)
    }

    @Test
    func floorQuotient_inexactDuration() {
        #expect(Meter.floorQuotient(beats(Number(1.5)), beats(frac(1, 2))) == 3)
    }

    @Test
    func remainder() {
        #expect(Meter.remainder(beats(frac(7, 4)), beats(frac(1, 2))) == beats(frac(1, 4)))
        #expect(Meter.remainder(1, beats(frac(1, 2))) == .zero)
        #expect(Meter.remainder(beats(frac(1, 4)), 1) == beats(frac(1, 4)))
    }
}
