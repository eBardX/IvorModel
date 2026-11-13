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
    // The last six rows are the worked example: one bar of 6/8 — 𝅘𝅥𝅮. 𝅘𝅥𝅯 ♪ ♪ ♪ ♪.
    //
    static let gridCases: [GridCase] = [GridCase(entries: [(0, "3/4")],
                                                 pickup: frac(1, 4),
                                                 time: 0,
                                                 expected: ExpectedPosition(0, 3, 0, frac(1, 4))),
                                        GridCase(entries: [(0, "3/4")],
                                                 pickup: frac(1, 4),
                                                 time: frac(1, 4),
                                                 expected: ExpectedPosition(1, 1, 0, frac(1, 4))),
                                        GridCase(entries: [(0, "3/4")],
                                                 pickup: frac(1, 4),
                                                 time: 1,
                                                 expected: ExpectedPosition(2, 1, 0, frac(1, 4))),
                                        GridCase(entries: [(0, "4/4"), (frac(3, 4), "4/4")],
                                                 pickup: 0,
                                                 time: frac(1, 2),
                                                 expected: ExpectedPosition(1, 3, 0, frac(1, 4))),
                                        GridCase(entries: [(0, "4/4"), (frac(3, 4), "4/4")],
                                                 pickup: 0,
                                                 time: frac(3, 4),
                                                 expected: ExpectedPosition(2, 1, 0, frac(1, 4))),
                                        GridCase(entries: [(0, "2+2+3/8")],
                                                 pickup: 0,
                                                 time: frac(1, 2),
                                                 expected: ExpectedPosition(1, 3, 0, frac(3, 8))),
                                        GridCase(entries: [(0, "2+2+3/8")],
                                                 pickup: 0,
                                                 time: frac(5, 8),
                                                 expected: ExpectedPosition(1, 3, frac(1, 8), frac(3, 8))),
                                        GridCase(entries: [(0, "free"), (frac(5, 2), "4/4")],
                                                 pickup: 0,
                                                 time: 1,
                                                 expected: ExpectedPosition(1, nil, 1, nil)),
                                        GridCase(entries: [(0, "free"), (frac(5, 2), "4/4")],
                                                 pickup: 0,
                                                 time: frac(5, 2),
                                                 expected: ExpectedPosition(2, 1, 0, frac(1, 4))),
                                        GridCase(entries: [(0, "4/3")],
                                                 pickup: 0,
                                                 time: frac(1, 2),
                                                 expected: ExpectedPosition(1, 2, frac(1, 6), frac(1, 3))),
                                        GridCase(entries: [(1, "3/4")],
                                                 pickup: 0,
                                                 time: frac(1, 2),
                                                 expected: nil),
                                        GridCase(entries: [(0, "6/8")],
                                                 pickup: 0,
                                                 time: 0,
                                                 expected: ExpectedPosition(1, 1, 0, frac(3, 8))),
                                        GridCase(entries: [(0, "6/8")],
                                                 pickup: 0,
                                                 time: frac(3, 16),
                                                 expected: ExpectedPosition(1, 1, frac(3, 16), frac(3, 8))),
                                        GridCase(entries: [(0, "6/8")],
                                                 pickup: 0,
                                                 time: frac(1, 4),
                                                 expected: ExpectedPosition(1, 1, frac(1, 4), frac(3, 8))),
                                        GridCase(entries: [(0, "6/8")],
                                                 pickup: 0,
                                                 time: frac(3, 8),
                                                 expected: ExpectedPosition(1, 2, 0, frac(3, 8))),
                                        GridCase(entries: [(0, "6/8")],
                                                 pickup: 0,
                                                 time: frac(1, 2),
                                                 expected: ExpectedPosition(1, 2, frac(1, 8), frac(3, 8))),
                                        GridCase(entries: [(0, "6/8")],
                                                 pickup: 0,
                                                 time: frac(5, 8),
                                                 expected: ExpectedPosition(1, 2, frac(1, 4), frac(3, 8)))]

    static let gridTables: [GridTable] = [GridTable(entries: [(0, "3/4")], pickup: frac(1, 4)),
                                          GridTable(entries: [(0, "3/4")], pickup: frac(1, 8)),
                                          GridTable(entries: [(0, "4/4"), (frac(3, 4), "4/4")], pickup: 0),
                                          GridTable(entries: [(0, "2+2+3/8")], pickup: 0),
                                          GridTable(entries: [(0, "free"), (frac(5, 2), "4/4")], pickup: 0),
                                          GridTable(entries: [(0, "4/3"), (frac(8, 3), "7/12")], pickup: 0),
                                          GridTable(entries: [(1, "3/4")], pickup: 0),
                                          GridTable(entries: [(0, "6/8"), (frac(7, 8), "3+2/8"), (2, "free"), (3, "5/8")], pickup: frac(1, 8)),
                                          GridTable(entries: [(0, "3/4"), (frac(1, 4), "2/4")], pickup: frac(1, 4))]

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

    static let pulseCases: [PulseCase] = [PulseCase(plain: "4/4", pulse: Array(repeating: frac(1, 4), count: 4), barLength: 1),
                                          PulseCase(plain: "3/4", pulse: Array(repeating: frac(1, 4), count: 3), barLength: frac(3, 4)),
                                          PulseCase(plain: "2/2", pulse: Array(repeating: frac(1, 2), count: 2), barLength: 1),
                                          PulseCase(plain: "3/2", pulse: Array(repeating: frac(1, 2), count: 3), barLength: frac(3, 2)),
                                          PulseCase(plain: "6/8", pulse: Array(repeating: frac(3, 8), count: 2), barLength: frac(3, 4)),
                                          PulseCase(plain: "9/8", pulse: Array(repeating: frac(3, 8), count: 3), barLength: frac(9, 8)),
                                          PulseCase(plain: "12/8", pulse: Array(repeating: frac(3, 8), count: 4), barLength: frac(3, 2)),
                                          PulseCase(plain: "3/8", pulse: [frac(3, 8)], barLength: frac(3, 8)),
                                          PulseCase(plain: "3/16", pulse: [frac(3, 16)], barLength: frac(3, 16)),
                                          PulseCase(plain: "5/8", pulse: Array(repeating: frac(1, 8), count: 5), barLength: frac(5, 8)),
                                          PulseCase(plain: "6/4", pulse: Array(repeating: frac(3, 4), count: 2), barLength: frac(3, 2)),
                                          PulseCase(plain: "9/16", pulse: Array(repeating: frac(3, 16), count: 3), barLength: frac(9, 16)),
                                          PulseCase(plain: "6/12", pulse: Array(repeating: frac(1, 4), count: 2), barLength: frac(1, 2)),
                                          PulseCase(plain: "3/12", pulse: [frac(1, 4)], barLength: frac(1, 4)),
                                          PulseCase(plain: "4/3", pulse: Array(repeating: frac(1, 3), count: 4), barLength: frac(4, 3)),
                                          PulseCase(plain: "7/12", pulse: Array(repeating: frac(1, 12), count: 7), barLength: frac(7, 12)),
                                          PulseCase(plain: "2+2+3/8", pulse: [frac(1, 4), frac(1, 4), frac(3, 8)], barLength: frac(7, 8)),
                                          PulseCase(plain: "3+2/8", pulse: [frac(3, 8), frac(1, 4)], barLength: frac(5, 8)),
                                          PulseCase(plain: "free", pulse: [], barLength: nil)]

    //
    // Five rising pitches, each with its own duration.
    //
    static let risingScale: [(Number, Number, Pitch)] = [(0, 1, .c4),
                                                         (1, 2, .d4),
                                                         (3, 3, .e4),
                                                         (6, 4, .f4),
                                                         (10, 5, .g4)]

    static let scalingCases: [ScalingCase] = [("3/4", ["3/2", "9/8", "3/3", "3/8", "3/12"]),
                                              ("6/8", ["6/4", "18/16", "6/6", "6/16", "6/24"]),
                                              ("2+2+3/8", ["2+2+3/4", "6+6+9/16", "2+2+3/6", "2+2+3/16", "2+2+3/24"])].flatMap { plain, expected in
        zip([2, frac(3, 2), frac(4, 3), frac(1, 2), frac(1, 3)], expected).map {
            ScalingCase(plain: plain, factor: $0, expected: $1)
        }
    }

    static let slowTempo = Tempo(96)

    static let threeNoteMelody: [(Number, Number, Pitch)] = [(0, 1, .c4), (1, 1, .e4), (2, 2, .g4)]
}
