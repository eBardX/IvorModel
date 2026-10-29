// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableAssemblerTests {
}

// MARK: -

extension NoteTableAssemblerTests {
    typealias NoteEventSB = NoteEvent<BeatTime, Pitch>  // SB: StandardBeat
    typealias NoteTableSB = NoteTable<BeatTime, Pitch>
    typealias TiedPitchSB = NoteEventSB.TiedPitch

    @Test
    func assemble_brokenTie_endWithoutStart_startsNewNote() {
        let events = [NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .a4,
                                                            endsTie: true)],
                                  duration: 1),
                      NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .e5)],
                                  duration: 1)]

        #expect(makeNoteTriplesSB(_assemble(events)) == makeNoteTriplesSB(makeNoteTableSB([(0, 1, .a4),
                                                                                           (1, 1, .e5)])))
    }

    @Test
    func assemble_brokenTie_startNotContinued_closesAtBoundary() {
        let events = [NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .a4,
                                                            startsTie: true)],
                                  duration: 1),
                      NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .e5)],
                                  duration: 1)]

        #expect(makeNoteTriplesSB(_assemble(events)) == makeNoteTriplesSB(makeNoteTableSB([(0, 1, .a4),
                                                                                           (1, 1, .e5)])))
    }

    @Test
    func assemble_brokenTie_startThenRest_closesAtBoundary() {
        let events = [NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .a4,
                                                            startsTie: true)],
                                  duration: 1),
                      NoteEventSB(duration: 2),
                      NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .a4,
                                                            endsTie: true)],
                                  duration: 1)]

        #expect(makeNoteTriplesSB(_assemble(events)) == makeNoteTriplesSB(makeNoteTableSB([(0, 1, .a4),
                                                                                           (3, 1, .a4)])))
    }

    @Test
    func assemble_brokenTie_stillOpenAtEnd_closesAtEnd() {
        let events = [NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .a4)],
                                  duration: 1),
                      NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .e5,
                                                            startsTie: true)],
                                  duration: 2)]

        #expect(makeNoteTriplesSB(_assemble(events)) == makeNoteTriplesSB(makeNoteTableSB([(0, 1, .a4),
                                                                                           (1, 2, .e5)])))
    }

    @Test
    func assemble_empty() {
        #expect(_assemble([]).notes.isEmpty)
    }

    @Test
    func assemble_tiedSlices_rejoinIntoOneNote() {
        let events = [NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .a4,
                                                            startsTie: true)],
                                  duration: 0.5),
                      NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .a4,
                                                            startsTie: true,
                                                            endsTie: true),
                                                TiedPitchSB(pitch: .e5)],
                                  duration: 0.5),
                      NoteEventSB(tiedPitches: [TiedPitchSB(pitch: .a4,
                                                            endsTie: true)],
                                  duration: 1)]

        #expect(makeNoteTriplesSB(_assemble(events)) == makeNoteTriplesSB(makeNoteTableSB([(0, 2, .a4),
                                                                                           (0.5, 0.5, .e5)])))
    }

    @Test(arguments: [// Monophonic
        [(0, 1, .a4), (1, 1, .cSharp5), (2, 1, .e5), (3, 1, .g5)],
                      // Overlapping
        [(0, 1, .a4), (0.5, 1, .cSharp5), (1, 1, .e5), (1.5, 1, .g5)],
                      // Chord with staggered releases
        [(0, 1, .a4), (0, 2, .cSharp5), (0, 3, .e5), (3, 1, .a4)],
                      // Leading and inner rests
        [(1, 1, .a4), (3, 0.5, .e5), (3, 1, .a4)],
                      // Unison doubling
        [(0, 2, .a4), (1, 2, .a4)]] as [[(attack: BeatTime, duration: BeatDuration, pitch: Pitch)]])
    func assemble_roundTrip(_ rawNotes: [(attack: BeatTime, duration: BeatDuration, pitch: Pitch)]) {
        let ntab = makeNoteTableSB(rawNotes)

        #expect(makeNoteTriplesSB(_assemble(ntab.extractNoteEvents())) == makeNoteTriplesSB(ntab))
    }
}

// MARK: - Private Functions

private func _assemble(_ noteEvents: [NoteEvent<BeatTime, Pitch>]) -> NoteTable<BeatTime, Pitch> {
    var assembler = NoteTable<BeatTime, Pitch>.Assembler(noteEvents: noteEvents)

    return assembler.assembleNoteTable()
}
