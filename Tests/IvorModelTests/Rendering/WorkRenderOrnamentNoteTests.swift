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
    func ornamentNote_flagsGraceNotesAndPartnerPitchesOnly() throws {
        let trill = try ornament(.trill, .step(.above, written: nil), OrnamentExecution(rate: .noteValue(positiveBeats(1, 12))))
        let fromPartner = try ornament(.trill,
                                       .step(.above, written: nil),
                                       OrnamentExecution(startNote: .partner, rate: .noteValue(positiveBeats(1, 12))))
        let notes = try renderedFlags([WrittenNote(0, frac(1, 4), .c4, Ornamentation(graceBefore: graceFigure([.b3], isSlashed: true),
                                                                                     ornament: trill)),
                                       WrittenNote(frac(1, 4), frac(1, 4), .e4, Ornamentation(ornament: fromPartner))])

        //
        // The grace note and each trill's partner pitch are flagged; every piece on a main pitch,
        // the trills' returns and held ends included, is not.
        //
        let fSharp4 = try #require(Pitch(plain: "F#4"))

        //
        // With no key, a step is a whole step: E4's partner is F♯4.
        //
        #expect(notes.count > 4)
        #expect(Set(notes.filter(\.isOrnamentNote).map(\.pitch)) == [.b3, .d4, fSharp4])
        #expect(Set(notes.filter { !$0.isOrnamentNote }.map(\.pitch)) == [.c4, .e4])
    }

    @Test
    func ornamentNote_noneOnARepeatedTremolo() throws {
        let strokes = try #require(TremoloStrokes(uintValue: 2))
        let tremolo = try ornament(.tremolo(.measured(strokes)), .repeat)
        let notes = try renderedFlags([WrittenNote(0, frac(1, 4), .c4, Ornamentation(ornament: tremolo))])

        #expect(notes.count > 1)
        #expect(notes.allSatisfy { !$0.isOrnamentNote })
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

    guard case let .standardBeat(parts, _, _, _) = try work.rendered().work.content.cases
    else { throw Work.Error.unsupportedStandardConversion }

    return try #require(parts.first).strands[0].noteTable
        .sorted { ($0.attack, $0.startPitch) < ($1.attack, $1.startPitch) }
        .map { ($0.startPitch, $0.extras?.contains(.ornamentNote) ?? false) }
}
