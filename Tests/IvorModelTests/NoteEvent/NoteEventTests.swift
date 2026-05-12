@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteEventTests {
}

// MARK: -

extension NoteEventTests {
    typealias NoteEventSB = NoteEvent<BeatTime, Pitch>  // SB: StandardBeat
    typealias TiedPitchS  = NoteEventSB.TiedPitch

    @Test
    func init_chord() {
        let expectedTiedPitches = [TiedPitchS(pitch: .a4),
                                   TiedPitchS(pitch: .cSharp5),
                                   TiedPitchS(pitch: .e5)]
        let expectedDuration = BeatDuration("3/2")
        let event = NoteEventSB(tiedPitches: expectedTiedPitches,
                                duration: expectedDuration)

        #expect(event.duration == expectedDuration)
        #expect(event.tiedPitches == expectedTiedPitches)
    }

    @Test
    func init_complex() {
        let expectedTiedPitches = [TiedPitchS(pitch: .a4,
                                              beginsTie: true),
                                   TiedPitchS(pitch: .d5,
                                              beginsTie: true,
                                              endsTie: true),
                                   TiedPitchS(pitch: .e5,
                                              endsTie: true),
                                   TiedPitchS(pitch: .g5)]
        let expectedDuration = BeatDuration("1/2")
        let event = NoteEventSB(tiedPitches: expectedTiedPitches,
                                duration: expectedDuration)

        #expect(event.duration == expectedDuration)
        #expect(event.tiedPitches == expectedTiedPitches)
    }

    @Test
    func init_rest() {
        let expectedDuration = BeatDuration(2)
        let event = NoteEventSB(duration: expectedDuration)

        #expect(event.duration == expectedDuration)
        #expect(event.tiedPitches.isEmpty)
    }

    @Test
    func init_single() {
        let expectedTiedPitches = [TiedPitchS(pitch: .a4)]
        let expectedDuration = BeatDuration("1/4")
        let event = NoteEventSB(tiedPitches: expectedTiedPitches,
                                duration: expectedDuration)

        #expect(event.duration == expectedDuration)
        #expect(event.tiedPitches == expectedTiedPitches)
    }
}
