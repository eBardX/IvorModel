// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

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
    ///             ``Template/Error/invalidTolerance`` if a tolerance’s value or the rest split’s
    ///             is invalid; ``Template/Error/incompatibleOptions`` if a tolerance or the rest
    ///             split doesn’t suit the work’s time basis or pitch notation; otherwise,
    ///             ``Template/Error/partNotFound(_:)`` if no part exists at `index`.
    public static func analyzeNoteEvents(in work: Work,
                                         at index: Int,
                                         options: AnalysisOptions) throws(Error) -> Self {
        try options.validate()

        let name = if work.name.isEmpty {
            "Analysis of \(work.workID)"
        } else {
            "Analysis of “\(work.name)”"
        }

        let (content, summary) = try _analyzeNoteEvents(in: work.content,
                                                        at: index,
                                                        options: options)

        return Self(name: name,
                    content: content,
                    analysisOptions: options,
                    analysisSummary: summary,
                    sources: Source(work: work,
                                    index: index).map { [$0] } ?? [],
                    sourceContext: SourceContext(content: work.content,
                                                 index: index))
    }

    /// Returns how many sequences analyzing a specific part of a work with the given recipe would
    /// learn from, without analyzing it.
    ///
    /// The count is of every variant that can be made, each split at its long rests (see
    /// ``AnalysisOptions/restSplit``), before any variant is merged because its states repeat an
    /// earlier one’s — so it is at least the ``AnalysisSummary/sequenceCount`` an analysis gives.
    /// Nothing is trained, so it is much cheaper than analyzing.
    ///
    /// - Parameter work:       The ``Work`` containing the part.
    /// - Parameter index:      The zero-based index of the part.
    /// - Parameter options:    The analysis recipe.
    ///
    /// - Returns:  The number of sequences.
    ///
    /// - Throws:   The same errors as ``analyzeNoteEvents(in:at:options:)``.
    public static func sequenceCount(in work: Work,
                                     at index: Int,
                                     options: AnalysisOptions) throws(Error) -> Int {
        try options.validate()

        switch work.content {
        case let .absoluteBeat(parts, _):
            return try _splitForms(of: parts,
                                   at: index,
                                   options: options,
                                   aligning: _beatAligning(options.timing),
                                   splitting: _beatSplitting(options.restSplit),
                                   transposing: _ratioTransposing).forms.reduce(0) { $0 + $1.count }

        case let .absoluteWall(parts):
            return try _splitForms(of: parts,
                                   at: index,
                                   options: options,
                                   aligning: _wallAligning(options.timing),
                                   splitting: _wallSplitting(options.restSplit),
                                   transposing: _ratioTransposing).forms.reduce(0) { $0 + $1.count }

        case let .keyboardBeat(parts, _):
            return try _splitForms(of: parts,
                                   at: index,
                                   options: options,
                                   aligning: _beatAligning(options.timing),
                                   splitting: _beatSplitting(options.restSplit),
                                   transposing: _noteDistanceTransposing).forms.reduce(0) { $0 + $1.count }

        case let .keyboardWall(parts):
            return try _splitForms(of: parts,
                                   at: index,
                                   options: options,
                                   aligning: _wallAligning(options.timing),
                                   splitting: _wallSplitting(options.restSplit),
                                   transposing: _noteDistanceTransposing).forms.reduce(0) { $0 + $1.count }

        case let .standardBeat(parts, _):
            return try _splitForms(of: parts,
                                   at: index,
                                   options: options,
                                   aligning: _beatAligning(options.timing),
                                   splitting: _beatSplitting(options.restSplit),
                                   transposing: _intervalTransposing).forms.reduce(0) { $0 + $1.count }

        case let .standardWall(parts):
            return try _splitForms(of: parts,
                                   at: index,
                                   options: options,
                                   aligning: _wallAligning(options.timing),
                                   splitting: _wallSplitting(options.restSplit),
                                   transposing: _intervalTransposing).forms.reduce(0) { $0 + $1.count }
        }
    }

    // MARK: Public Instance Methods

    /// Returns a new template that has learned a part of a work as well as everything this
    /// template has.
    ///
    /// The part is analyzed with this template’s own ``analysisOptions``, unchanged, and its
    /// chains are merged with this template’s. Each part keeps its own start and end: merging
    /// adds sequences, and never joins them. This template is unchanged, and may be locked.
    ///
    /// The new template’s vocabulary and ``analysisSummary`` add the two together, and its
    /// ``sources`` are this template’s with the part appended. Its vocabulary’s first event and its
    /// ``sourceContext`` are this template’s, so generation still starts where, and as, this
    /// template’s source did.
    ///
    /// A proportional duration tolerance groups each analysis’s durations on their own, so the
    /// same duration can be grouped differently in each.
    ///
    /// - Parameter index:  The zero-based index of the part to add.
    /// - Parameter work:   The ``Work`` containing the part.
    /// - Parameter name:   The display name of the new template. Its whitespace is normalized to
    ///                     a single line.
    ///
    /// - Returns:  A new ``Template``, with a new ID.
    ///
    /// - Throws:   ``Template/Error/incompatibleOptions`` if `work`’s pitch notation or time
    ///             basis isn’t this template’s; otherwise, ``Template/Error/partNotFound(_:)``
    ///             if no part exists at `index`.
    public func adding(partAt index: Int,
                       of work: Work,
                       name: String) throws(Error) -> Self {
        guard work.pitchNotation == pitchNotation,
              work.timeBasis == timeBasis
        else { throw Error.incompatibleOptions }

        let (added, summary) = try Self._analyzeNoteEvents(in: work.content,
                                                           at: index,
                                                           options: analysisOptions)

        return try Self(name: name,
                        content: Self._merge(content,
                                             with: added),
                        analysisOptions: analysisOptions,
                        analysisSummary: analysisSummary.adding(summary),
                        sources: sources + (Source(work: work,
                                                   index: index).map { [$0] } ?? []),
                        sourceContext: sourceContext)
    }

    // MARK: Private Type Aliases

    private typealias SplitForms<T: TimeProtocol, P: PitchProtocol> = (forms: [[[NoteEvent<T, P>]]], skipped: [Variant])
    private typealias TimingTolerance = AnalysisOptions.TimingTolerance
    private typealias Transposing<I: IntervalProtocol> = (AnalysisOptions.Transposition) -> DirectedInterval<I>?

    // MARK: Private Type Methods

    private static func _analyzeNoteEvents(in content: Work.Content,
                                           at index: Int,
                                           options: AnalysisOptions) throws(Error) -> (Self.Content, AnalysisSummary) {
        switch content {
        case let .absoluteBeat(parts, _):
            let (model, summary) = try _analyzeNoteEvents(in: parts,
                                                          at: index,
                                                          options: options,
                                                          aligning: _beatAligning(options.timing),
                                                          splitting: _beatSplitting(options.restSplit),
                                                          grouping: beatGrouping(options.durations),
                                                          rounding: frequencyRounding(options.pitches),
                                                          transposing: _ratioTransposing)

            return (.absoluteBeat(model), summary)

        case let .absoluteWall(parts):
            let (model, summary) = try _analyzeNoteEvents(in: parts,
                                                          at: index,
                                                          options: options,
                                                          aligning: _wallAligning(options.timing),
                                                          splitting: _wallSplitting(options.restSplit),
                                                          grouping: wallGrouping(options.durations),
                                                          rounding: frequencyRounding(options.pitches),
                                                          transposing: _ratioTransposing)

            return (.absoluteWall(model), summary)

        case let .keyboardBeat(parts, _):
            let (model, summary) = try _analyzeNoteEvents(in: parts,
                                                          at: index,
                                                          options: options,
                                                          aligning: _beatAligning(options.timing),
                                                          splitting: _beatSplitting(options.restSplit),
                                                          grouping: beatGrouping(options.durations),
                                                          rounding: exactRounding(options.pitches),
                                                          transposing: _noteDistanceTransposing)

            return (.keyboardBeat(model), summary)

        case let .keyboardWall(parts):
            let (model, summary) = try _analyzeNoteEvents(in: parts,
                                                          at: index,
                                                          options: options,
                                                          aligning: _wallAligning(options.timing),
                                                          splitting: _wallSplitting(options.restSplit),
                                                          grouping: wallGrouping(options.durations),
                                                          rounding: exactRounding(options.pitches),
                                                          transposing: _noteDistanceTransposing)

            return (.keyboardWall(model), summary)

        case let .standardBeat(parts, _):
            let (model, summary) = try _analyzeNoteEvents(in: parts,
                                                          at: index,
                                                          options: options,
                                                          aligning: _beatAligning(options.timing),
                                                          splitting: _beatSplitting(options.restSplit),
                                                          grouping: beatGrouping(options.durations),
                                                          rounding: exactRounding(options.pitches),
                                                          transposing: _intervalTransposing)

            return (.standardBeat(model), summary)

        case let .standardWall(parts):
            let (model, summary) = try _analyzeNoteEvents(in: parts,
                                                          at: index,
                                                          options: options,
                                                          aligning: _wallAligning(options.timing),
                                                          splitting: _wallSplitting(options.restSplit),
                                                          grouping: wallGrouping(options.durations),
                                                          rounding: exactRounding(options.pitches),
                                                          transposing: _intervalTransposing)

            return (.standardWall(model), summary)
        }
    }

    //
    // `aligning` adjusts the part's times before it's sliced; `grouping` maps each duration to its
    // representative (a duration it leaves out stays as it is); `rounding` maps each pitch to its
    // representative; and `transposing` gives a transposition's interval, or `nil` if it doesn't
    // suit the pitch notation.  The vocabulary records the representatives, and — where a
    // tolerance grouped them — the members of each; the chain learns states of the
    // representatives.
    //
    // Each variant is made from the aligned note table and sliced into note events of its own,
    // then split into sequences at each rest that `splitting` says is long enough — the rest
    // itself dropped.  Durations are grouped over the events of every variant together, so that a
    // group is the same in each.  A variant whose states repeat an earlier one's is merged — not trained, and
    // not counted in the vocabulary — and one that can't be made is skipped.  The original is
    // always first, so the vocabulary's first event is the original's.
    //
    private static func _analyzeNoteEvents<T, P>(in parts: [Part<T, P>],
                                                 at index: Int,
                                                 options: AnalysisOptions,
                                                 aligning: (NoteTable<T, P>) -> NoteTable<T, P>,
                                                 splitting: (T.DurationType) -> Bool,
                                                 grouping: ([T.DurationType]) -> [T.DurationType: T.DurationType],
                                                 rounding: (P) -> P,
                                                 transposing: Transposing<P.IntervalType>) throws(Error) -> (Model<T, P>, AnalysisSummary)
        where T.DurationType: TemplateDuration {
        let (splitForms, skippedVariants) = try _splitForms(of: parts,
                                                            at: index,
                                                            options: options,
                                                            aligning: aligning,
                                                            splitting: splitting,
                                                            transposing: transposing)
        let representatives = grouping(splitForms.flatMap { $0.flatMap { $0.map(\.duration) } })

        var durationMembers: [T.DurationType: [T.DurationType: Int]] = [:]
        var durations: [T.DurationType: Int] = [:]
        var first: NoteEvent<T, P>?
        var mergedCount = 0
        var pitchMembers: [P: [P: Int]] = [:]
        var pitches: [P: Int] = [:]
        var seen: Set<[[State<T, P>]]> = []
        var sequences: [[State<T, P>]] = []

        for form in splitForms {
            let tolerated = form.map { noteEvents in
                noteEvents.map {
                    NoteEvent<T, P>(tiedPitches: roundedPitches($0.tiedPitches,
                                                                with: rounding),
                                    duration: representatives[$0.duration] ?? $0.duration)
                }
            }

            //
            // Each sequence starts afresh, as a separate part would.
            //
            let formStates = tolerated.map { noteEvents in
                var builder = StateBuilder<T, P>(recipe: options.states)

                return noteEvents.map { builder.state(for: $0) }
            }

            guard seen.insert(formStates).inserted
            else {
                mergedCount += 1
                continue
            }

            sequences.append(contentsOf: formStates)

            if first == nil {
                first = tolerated.first?.first
            }

            for (noteEvent, toleratedEvent) in zip(form.joined(), tolerated.joined()) {
                if options.durations != nil {
                    durationMembers[toleratedEvent.duration, default: [:]][noteEvent.duration, default: 0] += 1
                }

                if options.pitches != nil {
                    for tiedPitch in noteEvent.tiedPitches {
                        pitchMembers[rounding(tiedPitch.pitch), default: [:]][tiedPitch.pitch, default: 0] += 1
                    }
                }

                durations[toleratedEvent.duration, default: 0] += 1

                for tiedPitch in toleratedEvent.tiedPitches {
                    pitches[tiedPitch.pitch, default: 0] += 1
                }
            }
        }

        let model = try Model(chains: _chains(of: sequences,
                                              options: options),
                              vocabulary: Vocabulary(durations: durations,
                                                     pitches: pitches,
                                                     first: first,
                                                     durationMembers: durationMembers,
                                                     pitchMembers: pitchMembers))

        return (model, AnalysisSummary(sequenceCount: sequences.count,
                                       mergedCount: mergedCount,
                                       skippedVariants: skippedVariants))
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

    private static func _beatSplitting(_ restSplit: AnalysisOptions.RestSplit?) throws(Error) -> (BeatDuration) -> Bool {
        switch restSplit {
        case let .beat(minimum):
            return { $0 >= minimum }

        case .wall:
            throw .incompatibleOptions

        case nil:
            return { _ in false }
        }
    }

    //
    // One joint chain, or — when the recipe separates them — a duration chain over every event's
    // duration and rest flag, and a pitch chain over the sounding events' pitches alone.  Each
    // sequence has its own start and end.
    //
    private static func _chains<T, P>(of sequences: [[State<T, P>]],
                                      options: AnalysisOptions) throws(Error) -> Model<T, P>.Chains where T.DurationType: TemplateDuration {
        func train(_ sequences: [[State<T, P>]]) throws(Error) -> MarkovChain<State<T, P>> {
            guard let markovChain = MarkovChain<State<T, P>>(maximumOrder: options.maximumOrder)
            else { throw Error.invalidMaximumOrder }

            markovChain.analyzer().analyze(sequences: sequences)

            return markovChain
        }

        guard options.states.separatesPitchAndDuration
        else { return try .joint(train(sequences)) }

        return try .separate(duration: train(sequences.map { $0.map(\.durationHalf) }),
                             pitch: train(sequences.map { $0.filter { !$0.isRest }.map(\.pitchHalf) }))
    }

    //
    // The note events of each variant that can be made, the original first, and the variants that
    // can't.
    //
    private static func _forms<T, P>(of noteTable: NoteTable<T, P>,
                                     variants: AnalysisOptions.Variants,
                                     transposing: Transposing<P.IntervalType>) throws(Error) -> ([[NoteEvent<T, P>]], [Variant]) {
        var intervals: [AnalysisOptions.Transposition: DirectedInterval<P.IntervalType>] = [:]

        for transposition in variants.transpositions {
            guard let interval = transposing(transposition)
            else { throw Error.incompatibleOptions }

            intervals[transposition] = interval
        }

        var forms: [[NoteEvent<T, P>]] = []
        var skippedVariants: [Variant] = []

        for variant in variants.all {
            if let noteEvents = _noteEvents(of: noteTable,
                                            as: variant,
                                            intervals: intervals) {
                forms.append(noteEvents)
            } else {
                skippedVariants.append(variant)
            }
        }

        return (forms, skippedVariants)
    }

    private static func _intervalTransposing(_ transposition: AnalysisOptions.Transposition) -> DirectedInterval<Interval>? {
        guard case let .interval(directedInterval) = transposition
        else { return nil }

        return directedInterval
    }

    private static func _merge(_ content: Content,
                               with other: Content) throws(Error) -> Content {
        switch (content, other) {
        case let (.absoluteBeat(lhs), .absoluteBeat(rhs)):
            try .absoluteBeat(_merge(lhs, with: rhs))

        case let (.absoluteWall(lhs), .absoluteWall(rhs)):
            try .absoluteWall(_merge(lhs, with: rhs))

        case let (.keyboardBeat(lhs), .keyboardBeat(rhs)):
            try .keyboardBeat(_merge(lhs, with: rhs))

        case let (.keyboardWall(lhs), .keyboardWall(rhs)):
            try .keyboardWall(_merge(lhs, with: rhs))

        case let (.standardBeat(lhs), .standardBeat(rhs)):
            try .standardBeat(_merge(lhs, with: rhs))

        case let (.standardWall(lhs), .standardWall(rhs)):
            try .standardWall(_merge(lhs, with: rhs))

        default:
            throw Error.incompatibleOptions
        }
    }

    //
    // `model`'s chains, then `other`'s, merged into new chains of the same maximum order, and their
    // vocabularies added together.  Both come from the same recipe, so their chains are of the
    // same kind; anything else is `incompatibleOptions`.
    //
    private static func _merge<T, P>(_ model: Model<T, P>,
                                     with other: Model<T, P>) throws(Error) -> Model<T, P> where T.DurationType: TemplateDuration {
        func merged(_ chains: MarkovChain<State<T, P>>...) throws(Error) -> MarkovChain<State<T, P>> {
            guard let markovChain = MarkovChain<State<T, P>>(maximumOrder: model.chains.maximumOrder)
            else { throw Error.invalidMaximumOrder }

            for chain in chains {
                markovChain.analyzer().merge(chain)
            }

            return markovChain
        }

        let chains: Model<T, P>.Chains = switch (model.chains, other.chains) {
        case let (.joint(lhs), .joint(rhs)):
            try .joint(merged(lhs, rhs))

        case let (.separate(lhsDuration, lhsPitch), .separate(rhsDuration, rhsPitch)):
            try .separate(duration: merged(lhsDuration, rhsDuration),
                          pitch: merged(lhsPitch, rhsPitch))

        default:
            throw Error.incompatibleOptions
        }

        return Model(chains: chains,
                     vocabulary: model.vocabulary.adding(other.vocabulary))
    }

    private static func _noteDistanceTransposing(_ transposition: AnalysisOptions.Transposition) -> DirectedInterval<NoteDistance>? {
        guard case let .noteDistance(directedInterval) = transposition
        else { return nil }

        return directedInterval
    }

    //
    // The variant's note events: `noteTable` inverted around its own pitch range, transposed,
    // reversed within its own time range, and scaled in time from its start, as `variant` says —
    // or `nil` if a transform fails.
    //
    private static func _noteEvents<T, P>(of noteTable: NoteTable<T, P>,
                                          as variant: Variant,
                                          intervals: [AnalysisOptions.Transposition: DirectedInterval<P.IntervalType>]) -> [NoteEvent<T, P>]? {
        var noteTable = noteTable

        do {
            if variant.isInverted {
                try noteTable.invert()
            }

            if let transposition = variant.transposition,
               let interval = intervals[transposition] {
                try noteTable.transpose(by: interval)
            }

            if variant.isRetrograde {
                try noteTable.reverse()
            }

            if let timeFactor = variant.timeFactor {
                if timeFactor > 1 {
                    try noteTable.augment(by: timeFactor)
                } else {
                    try noteTable.diminish(by: 1 / timeFactor)
                }
            }
        } catch {
            return nil
        }

        return noteTable.extractNoteEvents()
    }

    private static func _noteTable<T, P>(in parts: [Part<T, P>],
                                         at index: Int) throws(Error) -> NoteTable<T, P> {
        guard parts.indices.contains(index)
        else { throw Error.partNotFound(index) }

        return parts[index].noteTable
    }

    private static func _ratioTransposing(_ transposition: AnalysisOptions.Transposition) -> DirectedInterval<Ratio>? {
        guard case let .ratio(directedInterval) = transposition
        else { return nil }

        return directedInterval
    }

    //
    // `noteEvents` split into sequences at each rest that `isLong` says is long enough, the rest
    // dropped.  A sequence is never empty, so there are none for a part of nothing but long
    // rests.
    //
    private static func _split<T, P>(_ noteEvents: [NoteEvent<T, P>],
                                     at isLong: (T.DurationType) -> Bool) -> [[NoteEvent<T, P>]] {
        noteEvents
            .split { $0.tiedPitches.isEmpty && isLong($0.duration) }
            .map(Array.init)
    }

    //
    // Each variant that can be made, as its sequences — split at its long rests, which are
    // dropped — and the variants that can't.
    //
    private static func _splitForms<T, P>(of parts: [Part<T, P>],
                                          at index: Int,
                                          options: AnalysisOptions,
                                          aligning: (NoteTable<T, P>) -> NoteTable<T, P>,
                                          splitting: (T.DurationType) -> Bool,
                                          transposing: Transposing<P.IntervalType>) throws(Error) -> SplitForms<T, P> {
        let (forms, skippedVariants) = try _forms(of: aligning(_noteTable(in: parts,
                                                                          at: index)),
                                                  variants: options.variants,
                                                  transposing: transposing)

        return (forms.map { _split($0, at: splitting) }, skippedVariants)
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

    private static func _wallSplitting(_ restSplit: AnalysisOptions.RestSplit?) throws(Error) -> (WallDuration) -> Bool {
        switch restSplit {
        case .beat:
            throw .incompatibleOptions

        case let .wall(minimum):
            return { $0 >= minimum }

        case nil:
            return { _ in false }
        }
    }
}
