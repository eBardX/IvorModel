// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableExtractorTests {
}

// MARK: -

extension NoteTableExtractorTests {
    typealias NoteEventSB = NoteEvent<BeatTime, Pitch>  // SB: StandardBeat
    typealias NoteTableSB = NoteTable<BeatTime, Pitch>
    typealias TiedPitchSB = NoteEventSB.TiedPitch

    @Test
    func extract_monophonic() throws {
        let ntab = makeNoteTableSB([(0, 1, .a4),
                                    (1, 1, .cSharp5),
                                    (2, 1, .e5),
                                    (3, 1, .g5)])
        let expectedEvents: [NoteEventSB] = [NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .a4)],
                                                         duration: 1),
                                             NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .cSharp5)],
                                                         duration: 1),
                                             NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .e5)],
                                                         duration: 1),
                                             NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .g5)],
                                                         duration: 1)]

        let actualEvents = try ntab.extractNoteEvents()

        #expect(actualEvents == expectedEvents)
    }

    @Test
    func extract_polyphonic() throws {
        let ntab = makeNoteTableSB([(0, 1, .a4),
                                    (0.5, 1, .cSharp5),
                                    (1, 1, .e5),
                                    (1.5, 1, .g5)])
        let expectedEvents: [NoteEventSB] = [NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .a4,
                                                                                   beginsTie: true)],
                                                         duration: 0.5),
                                             NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .a4,
                                                                                   endsTie: true),
                                                                       TiedPitchSB(pitch: .cSharp5,
                                                                                   beginsTie: true)],
                                                         duration: 0.5),
                                             NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .cSharp5,
                                                                                   endsTie: true),
                                                                       TiedPitchSB(pitch: .e5,
                                                                                   beginsTie: true)],
                                                         duration: 0.5),
                                             NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .e5,
                                                                                   endsTie: true),
                                                                       TiedPitchSB(pitch: .g5,
                                                                                   beginsTie: true)],
                                                         duration: 0.5),
                                             NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .g5,
                                                                                   endsTie: true)],
                                                         duration: 0.5)]

        let actualEvents = try ntab.extractNoteEvents()

        #expect(actualEvents == expectedEvents)
    }
}
