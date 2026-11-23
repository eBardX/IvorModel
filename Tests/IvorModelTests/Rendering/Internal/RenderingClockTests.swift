// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct RenderingClockTests {
}

// MARK: -

extension RenderingClockTests {
    @Test
    func initBeat_defaultGracePerNoteIsASixtyFourth() {
        #expect(beatRenderingClock().defaultGracePerNote == frac(1, 64))
    }

    @Test
    func initBeat_eighth() {
        #expect(beatRenderingClock().eighth == frac(1, 8))
    }

    @Test
    func initBeat_isCompound() throws {
        let clock = try beatRenderingClock(meterTable: makeMeterTable([(0, "6/8"), (1, "3/8"), (2, "3/4"), (3, "12/8")]))

        #expect(clock.isCompound(frac(1, 2)))
        #expect(!clock.isCompound(frac(3, 2)))
        #expect(!clock.isCompound(frac(5, 2)))
        #expect(clock.isCompound(4))
        #expect(clock.isCompound(-1))
    }

    @Test
    func initBeat_isCompoundWithNoMeter() {
        #expect(!beatRenderingClock().isCompound(0))
    }

    @Test
    func initBeat_key() throws {
        let clock = try beatRenderingClock(keyTable: makeKeyTable([(1, -1)]))

        #expect(clock.key(2) == key(-1))
        #expect(clock.key(-1) == clock.key(0))
    }

    @Test
    func initBeat_length() {
        //
        // At ♩ = 60 a second is a quarter note.
        //
        #expect(isClose(beatRenderingClock().length(1, 0), frac(1, 4)))
        #expect(isClose(beatRenderingClock().length(2, 3), frac(1, 2)))
    }

    @Test
    func initBeat_seconds() {
        #expect(isClose(beatRenderingClock().seconds(0, frac(1, 2)), 2))
        #expect(isClose(beatRenderingClock().seconds(-frac(1, 4), 0), 0))
    }

    @Test
    func initBeat_subdivision() throws {
        #expect(try beatRenderingClock().subdivision(#require(TremoloStrokes(uintValue: 2))) == frac(1, 16))
        #expect(try beatRenderingClock().subdivision(#require(TremoloStrokes(uintValue: 1))) == frac(1, 8))
    }

    @Test
    func initWall_hasNoMeterKeyOrSubdivision() throws {
        let clock = RenderingClock()

        #expect(clock.eighth == nil)
        #expect(!clock.isCompound(0))
        #expect(clock.key(0) == nil)
        #expect(try clock.subdivision(#require(TremoloStrokes(uintValue: 2))) == nil)
    }

    @Test
    func initWall_lengthsAreSeconds() {
        let clock = RenderingClock()

        #expect(clock.defaultGracePerNote == frac(1, 25))
        #expect(clock.length(frac(3, 2), 7) == frac(3, 2))
        #expect(clock.seconds(1, frac(5, 2)) == frac(3, 2))
    }
}
