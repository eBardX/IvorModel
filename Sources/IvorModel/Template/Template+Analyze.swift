// © 2025–2026 John Gary Pusey (see LICENSE.md)

private import Foundation
private import IvorTiming
private import IvorTuning
private import XestiMarkov
private import XestiNumbers

extension Template {

    // MARK: Public Type Methods

    /// Creates a template by analyzing the note events of a specific part in a work, exactly.
    ///
    /// The same as ``analyzeNoteEvents(in:at:options:)`` with
    /// `AnalysisOptions(maximumOrder: maximumOrder)`.
    ///
    /// - Parameter work:           The ``Work`` containing the part to analyze.
    /// - Parameter index:          The zero-based index of the part to analyze.
    /// - Parameter maximumOrder:   The maximum pattern depth for the analysis.
    ///
    /// - Returns:  A new ``Template`` capturing the musical character of the specified part.
    ///
    /// - Throws:   ``Template/Error/invalidMaximumOrder`` if `maximumOrder` is not positive;
    ///             otherwise, ``Template/Error/partNotFound(_:)`` if no part exists at `index`.
    public static func analyzeNoteEvents(in work: Work,
                                         at index: Int,
                                         maximumOrder: Int) throws(Error) -> Self {
        try analyzeNoteEvents(in: work,
                              at: index,
                              options: AnalysisOptions(maximumOrder: maximumOrder))
    }

    /// Creates a template by analyzing the note events of a specific part in a work, with the
    /// given tolerances.
    ///
    /// The work is not changed. The template records `options`.
    ///
    /// - Parameter work:       The ``Work`` containing the part to analyze.
    /// - Parameter index:      The zero-based index of the part to analyze.
    /// - Parameter options:    The analysis recipe.
    ///
    /// - Returns:  A new ``Template`` capturing the musical character of the specified part.
    ///
    /// - Throws:   ``Template/Error/invalidMaximumOrder`` if the maximum order is not positive;
    ///             ``Template/Error/invalidTolerance`` if a tolerance’s value is invalid;
    ///             ``Template/Error/incompatibleOptions`` if a tolerance doesn’t suit the work’s
    ///             time basis or pitch notation; otherwise, ``Template/Error/partNotFound(_:)``
    ///             if no part exists at `index`.
    public static func analyzeNoteEvents(in work: Work,
                                         at index: Int,
                                         options: AnalysisOptions) throws(Error) -> Self {
        try options.validate()

        let name = if work.name.isEmpty {
            "Analysis of \(work.workID)"
        } else {
            "Analysis of “\(work.name)”"
        }

        return try Self(name: name,
                        content: _analyzeNoteEvents(in: work.content,
                                                    at: index,
                                                    options: options),
                        analysisOptions: options)
    }

    // MARK: Private Type Aliases

    private typealias DurationTolerance = AnalysisOptions.DurationTolerance
    private typealias PitchTolerance    = AnalysisOptions.PitchTolerance
    private typealias TimingTolerance   = AnalysisOptions.TimingTolerance

    // MARK: Private Type Methods

    private static func _analyzeNoteEvents(in content: Work.Content,
                                           at index: Int,
                                           options: AnalysisOptions) throws(Error) -> Self.Content {
        switch content {
        case let .absoluteBeat(parts, _):
            try .absoluteBeat(_analyzeNoteEvents(in: parts,
                                                 at: index,
                                                 options: options,
                                                 aligning: _beatAligning(options.timing),
                                                 grouping: _beatGrouping(options.durations),
                                                 rounding: _frequencyRounding(options.pitches)))

        case let .absoluteWall(parts):
            try .absoluteWall(_analyzeNoteEvents(in: parts,
                                                 at: index,
                                                 options: options,
                                                 aligning: _wallAligning(options.timing),
                                                 grouping: _wallGrouping(options.durations),
                                                 rounding: _frequencyRounding(options.pitches)))

        case let .keyboardBeat(parts, _):
            try .keyboardBeat(_analyzeNoteEvents(in: parts,
                                                 at: index,
                                                 options: options,
                                                 aligning: _beatAligning(options.timing),
                                                 grouping: _beatGrouping(options.durations),
                                                 rounding: _exactRounding(options.pitches)))

        case let .keyboardWall(parts):
            try .keyboardWall(_analyzeNoteEvents(in: parts,
                                                 at: index,
                                                 options: options,
                                                 aligning: _wallAligning(options.timing),
                                                 grouping: _wallGrouping(options.durations),
                                                 rounding: _exactRounding(options.pitches)))

        case let .standardBeat(parts, _):
            try .standardBeat(_analyzeNoteEvents(in: parts,
                                                 at: index,
                                                 options: options,
                                                 aligning: _beatAligning(options.timing),
                                                 grouping: _beatGrouping(options.durations),
                                                 rounding: _exactRounding(options.pitches)))

        case let .standardWall(parts):
            try .standardWall(_analyzeNoteEvents(in: parts,
                                                 at: index,
                                                 options: options,
                                                 aligning: _wallAligning(options.timing),
                                                 grouping: _wallGrouping(options.durations),
                                                 rounding: _exactRounding(options.pitches)))
        }
    }

    //
    // `aligning` adjusts the part's times before it's sliced; `grouping` maps each duration to its
    // representative (a duration it leaves out stays as it is); and `rounding` maps each pitch to
    // its representative.  The vocabulary records the representatives, and — where a tolerance
    // grouped them — the members of each; the chain learns states of the representatives.
    //
    private static func _analyzeNoteEvents<T, P>(in parts: [Part<T, P>],
                                                 at index: Int,
                                                 options: AnalysisOptions,
                                                 aligning: (NoteTable<T, P>) -> NoteTable<T, P>,
                                                 grouping: ([T.DurationType]) -> [T.DurationType: T.DurationType],
                                                 rounding: (P) -> P) throws(Error) -> Model<T, P> where T.DurationType: TemplateDuration {
        let noteEvents = try aligning(_noteTable(in: parts,
                                                 at: index)).extractNoteEvents()
        let representatives = grouping(noteEvents.map(\.duration))

        var durationMembers: [T.DurationType: [T.DurationType: Int]] = [:]
        var durations: [T.DurationType: Int] = [:]
        var pitchMembers: [P: [P: Int]] = [:]
        var pitches: [P: Int] = [:]
        var tolerated: [NoteEvent<T, P>] = []

        for noteEvent in noteEvents {
            let duration = representatives[noteEvent.duration] ?? noteEvent.duration

            if options.durations != nil {
                durationMembers[duration, default: [:]][noteEvent.duration, default: 0] += 1
            }

            if options.pitches != nil {
                for tiedPitch in noteEvent.tiedPitches {
                    pitchMembers[rounding(tiedPitch.pitch), default: [:]][tiedPitch.pitch, default: 0] += 1
                }
            }

            let toleratedEvent = NoteEvent<T, P>(tiedPitches: _rounding(noteEvent.tiedPitches,
                                                                        with: rounding),
                                                 duration: duration)

            durations[duration, default: 0] += 1

            for tiedPitch in toleratedEvent.tiedPitches {
                pitches[tiedPitch.pitch, default: 0] += 1
            }

            tolerated.append(toleratedEvent)
        }

        var builder = StateBuilder<T, P>(recipe: options.states)

        let states = tolerated.map { builder.state(for: $0) }

        return try Model(chains: _chains(of: states,
                                         options: options),
                         vocabulary: Vocabulary(durations: durations,
                                                pitches: pitches,
                                                first: tolerated.first,
                                                durationMembers: durationMembers,
                                                pitchMembers: pitchMembers))
    }

    private static func _beatAligning<P>(_ timing: TimingTolerance?) throws(Error) -> (NoteTable<BeatTime, P>) -> NoteTable<BeatTime, P> {
        switch timing {
        case let .grid(factors):
            guard let quantizer = try? BeatQuantizer(factors: factors)
            else { throw .invalidTolerance }

            return {
                var noteTable = $0

                noteTable.quantize(using: quantizer)

                return noteTable
            }

        case .window:
            throw .incompatibleOptions

        case nil:
            return { $0 }
        }
    }

    private static func _beatGrouping(_ durations: DurationTolerance?) throws(Error) -> ([BeatDuration]) -> [BeatDuration: BeatDuration] {
        switch durations {
        case let .proportional(fraction):
            return { _proportionalGroups(of: $0, within: fraction) }

        case .step:
            throw .incompatibleOptions

        case nil:
            return { _ in [:] }
        }
    }

    //
    // One joint chain, or — when the recipe separates them — a duration chain over every event's
    // duration and rest flag, and a pitch chain over the sounding events' pitches alone.
    //
    private static func _chains<T, P>(of states: [State<T, P>],
                                      options: AnalysisOptions) throws(Error) -> Model<T, P>.Chains where T.DurationType: TemplateDuration {
        func train(_ sequence: [State<T, P>]) throws(Error) -> MarkovChain<State<T, P>> {
            guard let markovChain = MarkovChain<State<T, P>>(maximumOrder: options.maximumOrder)
            else { throw Error.invalidMaximumOrder }

            markovChain.analyzer().analyze(sequence: sequence)

            return markovChain
        }

        guard options.states.separatesPitchAndDuration
        else { return try .joint(train(states)) }

        return try .separate(duration: train(states.map(\.durationHalf)),
                             pitch: train(states.filter { !$0.isRest }.map(\.pitchHalf)))
    }

    private static func _exactRounding<P>(_ pitches: PitchTolerance?) throws(Error) -> (P) -> P {
        guard pitches == nil
        else { throw .incompatibleOptions }

        return { $0 }
    }

    //
    // Each frequency moves to the nearest whole number of `cents` steps from A4 = 440 Hz.
    //
    private static func _frequencyRounding(_ pitches: PitchTolerance?) -> (Frequency) -> Frequency {
        switch pitches {
        case let .cents(cents):
            { frequency in
                let steps = (1_200 * log2(frequency.doubleValue / 440) / cents).rounded()
                let rounded = 440 * pow(2, steps * cents / 1_200)

                return Frequency(numberValue: Number(floatLiteral: rounded)) ?? frequency
            }

        case nil:
            { $0 }
        }
    }

    private static func _noteTable<T, P>(in parts: [Part<T, P>],
                                         at index: Int) throws(Error) -> NoteTable<T, P> {
        guard parts.indices.contains(index)
        else { throw Error.partNotFound(index) }

        return parts[index].noteTable
    }

    //
    // Groups the distinct durations, shortest first, so that the longest in each group is at most
    // `1 + fraction` times the shortest, and maps each to its group's most common duration — the
    // shortest of those, on a tie.
    //
    private static func _proportionalGroups<D: DurationProtocol>(of durations: [D],
                                                                 within fraction: Double) -> [D: D] {
        var counts: [D: Int] = [:]

        for duration in durations {
            counts[duration, default: 0] += 1
        }

        let ratio = Number(floatLiteral: 1 + fraction)
        var groups: [[D]] = []

        for duration in counts.keys.sorted() {
            if let shortest = groups.last?.first,
               let limit = shortest.multiplied(by: ratio),
               duration <= limit {
                groups[groups.count - 1].append(duration)
            } else {
                groups.append([duration])
            }
        }

        var representatives: [D: D] = [:]

        for group in groups {
            var best = group[0]

            for duration in group where counts[duration, default: 0] > counts[best, default: 0] {
                best = duration
            }

            for duration in group {
                representatives[duration] = best
            }
        }

        return representatives
    }

    //
    // Pitches that round to the same pitch become one; the first, in the event's order, keeps
    // its ties.
    //
    private static func _rounding<T, P>(_ tiedPitches: [NoteEvent<T, P>.TiedPitch],
                                        with rounding: (P) -> P) -> [NoteEvent<T, P>.TiedPitch] {
        var seen: Set<P> = []

        return tiedPitches.compactMap { tiedPitch in
            let pitch = rounding(tiedPitch.pitch)

            guard seen.insert(pitch).inserted
            else { return nil }

            return NoteEvent<T, P>.TiedPitch(pitch: pitch,
                                             startsTie: tiedPitch.startsTie,
                                             endsTie: tiedPitch.endsTie)
        }
    }

    private static func _wallAligning<P>(_ timing: TimingTolerance?) throws(Error) -> (NoteTable<WallTime, P>) -> NoteTable<WallTime, P> {
        switch timing {
        case .grid:
            throw .incompatibleOptions

        case let .window(window):
            return { $0.mergingTimes(within: window) }

        case nil:
            return { $0 }
        }
    }

    //
    // A step rounds each duration to the nearest whole number of steps, but never below one.
    //
    private static func _wallGrouping(_ durations: DurationTolerance?) -> ([WallDuration]) -> [WallDuration: WallDuration] {
        switch durations {
        case let .proportional(fraction):
            { _proportionalGroups(of: $0, within: fraction) }

        case let .step(step):
            { durations in
                var representatives: [WallDuration: WallDuration] = [:]

                for duration in Set(durations) {
                    let steps = max(1, (duration.uintValue + step.uintValue / 2) / step.uintValue)

                    representatives[duration] = WallDuration(uintValue: steps * step.uintValue) ?? duration
                }

                return representatives
            }

        case nil:
            { _ in [:] }
        }
    }
}
