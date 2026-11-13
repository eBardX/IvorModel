// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import XestiNumbers
import XestiTools

enum Fixtures {
    /// The keys of an ascending E major scale, from E4 to E5.
    static let eMajorKeys: [NoteNumber] = [64, 66, 68, 69, 71, 73, 75, 76]

    static let flute = Instrument(stringValue: "Flute")! // swiftlint:disable:this force_unwrapping

    //
    // Down a perfect fourth to up an augmented fourth, without the unison.
    //
    static let keyboardTranspositions: [Template.AnalysisOptions.Transposition] = [5, 4, 3, 2, 1].map { descending($0) }
        + [1, 2, 3, 4, 5, 6].map { ascending($0) }

    static let leftPan = Pan(horizontal: -45)

    //
    // Four notes and a rest, with every pitch, duration, interval and ratio different.
    //
    static let melodyWithRest: [(Number, Number, Pitch)] = [(0, 1, .c4),
                                                            (1, 2, .d4),
                                                            (Number(numerator: 7, denominator: 2), 3, .f4),
                                                            (Number(numerator: 13, denominator: 2), Number(numerator: 5, denominator: 2), .b4)]

    static let oboe = Instrument(stringValue: "Oboe")! // swiftlint:disable:this force_unwrapping

    //
    // Every pitch and duration different, so each context leads to one place: the source itself.
    //
    static let phraseMelody: [(Number, Number, Pitch)] = [(0, 1, .c4),
                                                          (1, 2, .e4),
                                                          (3, Number(numerator: 1, denominator: 2), .g4),
                                                          (Number(numerator: 7, denominator: 2), 3, .b4)]

    //
    // Five rising pitches, each with its own duration.
    //
    static let risingScale: [(Number, Number, Pitch)] = [(0, 1, .c4),
                                                         (1, 2, .d4),
                                                         (3, 3, .e4),
                                                         (6, 4, .f4),
                                                         (10, 5, .g4)]

    static let slowTempo = Tempo(96)

    static let threeNoteMelody: [(Number, Number, Pitch)] = [(0, 1, .c4), (1, 1, .e4), (2, 2, .g4)]
}
