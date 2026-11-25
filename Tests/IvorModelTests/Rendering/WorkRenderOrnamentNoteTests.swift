// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

// Which rendered notes carry `Extra.ornamentNote`.
struct WorkRenderOrnamentNoteTests {
}

// MARK: -

extension WorkRenderOrnamentNoteTests {
    private typealias Ornamentation = BeatNotes.Ornamentation
    private typealias OrnamentExecution = BeatNotes.OrnamentExecution

    @Test
    func ornamentNote_flagsGraceNotesAndAlternationsButNotTheFirstMainPiece() throws {
        let trill = try ornament(.trill, .step(.above, written: nil), OrnamentExecution(rate: .noteValue(positiveBeats(1, 12))))
        let fromPartner = try ornament(.trill,
                                       .step(.above, written: nil),
                                       OrnamentExecution(startNote: .partner, rate: .noteValue(positiveBeats(1, 12))))
        let notes = try renderedFlags([WrittenNote(0, frac(1, 4), .c4, Ornamentation(graceBefore: graceFigure([.d4], isSlashed: true),
                                                                                     ornament: trill)),
                                       WrittenNote(frac(1, 4), frac(1, 4), .e4, Ornamentation(ornament: fromPartner))])

        //
        // The grace note and every piece but each trill's first on its main pitch are flagged.
        //
        #expect(notes.first?.pitch == .d4)
        #expect(notes.first?.isOrnamentNote == true)
        #expect(notes.count > 4)
        #expect(notes.filter { !$0.isOrnamentNote }.map(\.pitch) == [.c4, .e4])
    }

    @Test
    func ornamentNote_noneOnPlainNotesOrRolledChords() throws {
        let notes = try renderedFlags([WrittenNote(0, frac(1, 4), .c4, rollOrnamentation()),
                                       WrittenNote(0, frac(1, 4), .e4, rollOrnamentation()),
                                       WrittenNote(frac(1, 4), frac(1, 4), .g4)])

        #expect(notes.count == 3)
        #expect(notes.allSatisfy { !$0.isOrnamentNote })
    }
}

// MARK: - Private Functions

//
// The first part's rendered notes, ordered by start, then pitch, each with whether it carries
// `Extra.ornamentNote`.
//
private func renderedFlags(_ notes: [WrittenNote]) throws -> [(pitch: Pitch, isOrnamentNote: Bool)] {
    let work = try renderingWork([renderingPart(notes)])

    guard case let .standardBeat(parts, _, _, _) = try work.rendered().work.content
    else { throw Work.Error.unsupportedStandardConversion }

    return try #require(parts.first).noteTable
        .sorted { ($0.attack, $0.startPitch) < ($1.attack, $1.startPitch) }
        .map { ($0.startPitch, $0.extras?.contains(.ornamentNote) ?? false) }
}
