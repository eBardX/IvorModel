// © 2025–2026 John Gary Pusey (see LICENSE.md)

private import IvorTiming
private import XestiMarkov
private import XestiTools

extension Template {

    // MARK: Public Instance Methods

    /// Returns a new work generated from this template with the given recipe and seed.
    ///
    /// Generating from the same template with the same recipe and seed always gives the same
    /// notes. The new work records the recipe and seed in its ``Work/generation``. It has one
    /// part; a beat-time work gets a default tempo map.
    ///
    /// - Parameter name:       The name to assign to the generated work.
    /// - Parameter options:    The recipe to generate with. Its pitch notation and time basis must
    ///                         match this template’s.
    /// - Parameter seed:       The seed for the random choices made during generation.
    ///
    /// - Returns:  A new ``Work`` containing the generated note content.
    ///
    /// - Throws:   ``Template/Error/incompatibleOptions`` if `options` doesn’t match this
    ///             template’s pitch notation and time basis; otherwise, a
    ///             ``Template/Error`` describing the first invalid option.
    public func generateWork(name: String,
                             options: AnyGenerationOptions,
                             seed: UInt64) throws -> Work {
        try generateWork(name: name,
                         options: options,
                         seed: seed,
                         mixingWith: [])
    }

    /// Returns a new work generated from this template and the other templates its recipe mixes
    /// in, with the given recipe and seed.
    ///
    /// The recipe’s ``GenerationOptions/templateMix`` names the other templates; `others`
    /// supplies them, and may hold more. Generating with the same templates, recipe and seed
    /// always gives the same notes. The new work records the recipe, and so the mix, in its
    /// ``Work/generation``.
    ///
    /// - Parameter name:       The name to assign to the generated work.
    /// - Parameter options:    The recipe to generate with. Its pitch notation and time basis must
    ///                         match this template’s.
    /// - Parameter seed:       The seed for the random choices made during generation.
    /// - Parameter others:     The templates the recipe mixes in.
    ///
    /// - Returns:  A new ``Work`` containing the generated note content.
    ///
    /// - Throws:   ``Template/Error/templateNotFound(_:)`` if the recipe mixes in a template that
    ///             `others` doesn’t hold; ``Template/Error/incompatibleTemplates`` if one doesn’t
    ///             suit this template; ``Template/Error/incompatibleOptions`` if `options`
    ///             doesn’t match this template’s pitch notation and time basis; otherwise, a
    ///             ``Template/Error`` describing the first invalid option.
    public func generateWork(name: String,
                             options: AnyGenerationOptions,
                             seed: UInt64,
                             mixingWith others: [Template]) throws -> Work {
        try Work(name: name,
                 content: Self._generateWorkContent(from: content,
                                                    mixingWith: _mixedTemplates(for: options,
                                                                                among: others).map(\.content),
                                                    options: options,
                                                    analysisOptions: analysisOptions,
                                                    seed: seed),
                 generation: Work.Generation(templateID: templateID,
                                             templateName: self.name,
                                             options: options,
                                             seed: seed))
    }

    /// Returns a new work generated from this template with the given typed recipe and seed.
    ///
    /// This is equivalent to calling `generateWork(name:options:seed:)`
    /// with the recipe wrapped in ``Template/AnyGenerationOptions``.
    ///
    /// - Parameter name:       The name to assign to the generated work.
    /// - Parameter options:    The recipe to generate with. Its time and pitch types must match
    ///                         this template’s.
    /// - Parameter seed:       The seed for the random choices made during generation.
    ///
    /// - Returns:  A new ``Work`` containing the generated note content.
    ///
    /// - Throws:   ``Template/Error/incompatibleOptions`` if `options` doesn’t match this
    ///             template’s pitch notation and time basis; otherwise, a
    ///             ``Template/Error`` describing the first invalid option.
    public func generateWork(name: String,
                             options: GenerationOptions<some Any, some Any>,
                             seed: UInt64) throws -> Work {
        guard let anyOptions = AnyGenerationOptions(options)
        else { throw Error.incompatibleOptions }

        return try generateWork(name: name,
                                options: anyOptions,
                                seed: seed)
    }

    /// Returns a new work generated from this template at the given order, with a random seed.
    ///
    /// This is equivalent to calling `generateWork(name:options:seed:)`
    /// with the default recipe at `order`, a length of `limit` note events, and a random seed.
    ///
    /// - Parameter name:   The name to assign to the generated work.
    /// - Parameter order:  The pattern depth to use for generation.
    /// - Parameter limit:  The maximum number of note events to generate.
    ///
    /// - Returns:  A new ``Work`` containing the generated note content.
    ///
    /// - Throws:   ``Template/Error/invalidLimit`` if `limit` is not positive;
    ///             otherwise, ``Template/Error/invalidOrder(_:)`` if `order` exceeds
    ///             the template’s maximum supported depth.
    public func generateWork(name: String,
                             order: Int,
                             limit: Int) throws -> Work {
        try generateWork(name: name,
                         options: _defaultOptions(order: order,
                                                  limit: limit),
                         seed: UInt64.random(in: .min ... .max))
    }

    // MARK: Private Nested Types

    //
    // Lets a `MorphCurve`, which is `Codable` without depending on XestiTools, drive a morph.
    //
    private struct _CurveInterpolator: Interpolator {
        let curve: MorphCurve

        func interpolate(_ value: Double) -> Double {
            switch curve {
            case .cosine:
                CosineInterpolator().interpolate(value)

            case .linear:
                LinearInterpolator().interpolate(value)

            case let .logistic(steepness):
                LogisticInterpolator(steepness: steepness).interpolate(value)

            case let .power(power):
                PolynomialInterpolator(power: power).interpolate(value)
            }
        }
    }

    // MARK: Private Type Methods

    //
    // Builds the generator stack for the chain with `role`, in the order documented on
    // `GenerationOptions`: mixing (or the order alone), then constraints, then contrast, then
    // back-off, then looping. Every sampling generator gets its own seed, drawn in a fixed order
    // from `rng`, so the whole stack is reproducible.
    //
    // Constraints test realized note events (see `Realizer`) — or, for a separated template's
    // chains, the half of one that each chooses — and so does the range that a relative recipe
    // keeps to.  When the range rules out every choice, a fallback at the chain's order, under
    // the constraints alone, chooses instead, and the realizer brings the result back into range.
    // The duration chain chooses no pitches, so it has no range to keep to.
    //
    // A pitch chain isn't looped here: it's driven by `next(after:)` with a history that only the
    // caller can reset, so the caller loops it (see `_generateNoteEvents`).
    //
    //
    // The models of `others`, each of which must be of the case `model` picks out.
    //
    private static func _models<T, P>(_ others: [Template.Content],
                                      _ model: (Template.Content) -> Model<T, P>?) throws -> [Model<T, P>] where T.DurationType: TemplateDuration {
        try others.map { content in
            guard let model = model(content)
            else { throw Error.incompatibleTemplates }

            return model
        }
    }

    //
    // `chains` are this template's chain with `role`, then those of the templates the recipe mixes
    // in, in the mix's order.  Each gives a generator at an order, which the mix (if any) blends or
    // morphs; back-off builds the same mix at each lower order.
    //
    private static func _makeGenerator<T, P>(using chains: [MarkovChain<State<T, P>>],
                                             as role: ChainRole,
                                             chainOptions: GenerationOptions<T, P>.ChainOptions,
                                             options: GenerationOptions<T, P>,
                                             realizer: Realizer<T, P>,
                                             rng: inout SeededRandomNumberGenerator) throws -> any MarkovChain<State<T, P>>.Generator
        where T.DurationType: TemplateDuration {
        typealias Chain = MarkovChain<State<T, P>>

        let constraints = options.constraints
        let keepsToRange = role != .duration && realizer.range != nil

        func makeSimple(_ markovChain: Chain,
                        order: Int,
                        rng: inout SeededRandomNumberGenerator) throws -> any Chain.Generator {
            guard let generator = markovChain.generator(order: order,
                                                        startsAtBegin: options.startsAtBegin,
                                                        stopsAtEnd: options.stopsAtEnd,
                                                        using: SeededRandomNumberGenerator(seed: rng.next()))
            else { throw Error.invalidOrder(markovChain.maximumOrder) }

            return generator
        }

        func makeMixed(order: Int,
                       rng: inout SeededRandomNumberGenerator) throws -> any Chain.Generator {
            switch options.templateMix {
            case let .blend(shares):
                var sources = try [(generator: makeSimple(chains[0], order: order, rng: &rng),
                                    weight: 1 - shares.reduce(0) { $0 + $1.weight })]

                for (chain, share) in zip(chains.dropFirst(), shares) {
                    try sources.append((generator: makeSimple(chain, order: order, rng: &rng),
                                        weight: share.weight))
                }

                return Chain.generator(blending: sources,
                                       using: SeededRandomNumberGenerator(seed: rng.next()))

            case let .morph(_, steps, curve):
                return try Chain.generator(interpolating: makeSimple(chains[0], order: order, rng: &rng),
                                           to: makeSimple(chains[1], order: order, rng: &rng),
                                           over: steps,
                                           along: _CurveInterpolator(curve: curve),
                                           using: SeededRandomNumberGenerator(seed: rng.next()))

            case nil:
                return try makeSimple(chains[0], order: order, rng: &rng)
            }
        }

        func isConstrained(checkingRange: Bool) -> Bool {
            switch role {
            case .duration:
                constraints.maximumDuration != nil || !constraints.allowsRests

            case .joint:
                !constraints.isEmpty || (checkingRange && keepsToRange)

            case .pitch:
                constraints.allowedPitches != nil || constraints.pitchRange != nil || (checkingRange && keepsToRange)
            }
        }

        func decorate(_ generator: any Chain.Generator,
                      checkingRange: Bool,
                      rng: inout SeededRandomNumberGenerator) -> any Chain.Generator {
            var result = generator

            if isConstrained(checkingRange: checkingRange) {
                result = Chain.generator(filtering: result,
                                         where: { realizer.allows($0, as: role, checkingRange: checkingRange) },
                                         using: SeededRandomNumberGenerator(seed: rng.next()))
            }

            if chainOptions.contrast != 1 {
                result = Chain.generator(contrasting: result,
                                         by: chainOptions.contrast,
                                         using: SeededRandomNumberGenerator(seed: rng.next()))
            }

            return result
        }

        let primary: any Chain.Generator = switch chainOptions.mixing {
        case let .blend(otherOrder, weight):
            try Chain.generator(blending: [(makeSimple(chains[0], order: chainOptions.order, rng: &rng), weight: 1 - weight),
                                           (makeSimple(chains[0], order: otherOrder, rng: &rng), weight: weight)],
                                using: SeededRandomNumberGenerator(seed: rng.next()))

        case let .morph(otherOrder, steps, curve):
            try Chain.generator(interpolating: makeSimple(chains[0], order: chainOptions.order, rng: &rng),
                                to: makeSimple(chains[0], order: otherOrder, rng: &rng),
                                over: steps,
                                along: _CurveInterpolator(curve: curve),
                                using: SeededRandomNumberGenerator(seed: rng.next()))

        case nil:
            try makeMixed(order: chainOptions.order, rng: &rng)
        }

        var stack = decorate(primary,
                             checkingRange: true,
                             rng: &rng)

        if options.backsOff {
            for order in (0..<chainOptions.topOrder).reversed() {
                stack = try Chain.generator(trying: stack,
                                            otherwise: decorate(makeMixed(order: order, rng: &rng),
                                                                checkingRange: true,
                                                                rng: &rng))
            }
        }

        if keepsToRange {
            stack = try Chain.generator(trying: stack,
                                        otherwise: decorate(makeMixed(order: chainOptions.order, rng: &rng),
                                                            checkingRange: false,
                                                            rng: &rng))
        }

        if options.loops, role != .pitch {
            stack = Chain.generator(looping: stack)
        }

        return stack
    }

    //
    // Generates states until `step` returns `true` for one: from the joint chain alone, or from a
    // separated template's two chains in step.  For each duration state that isn't a rest, the
    // pitch chain chooses the next pitch state from those it chose before; the two halves are
    // joined into the state that `step` gets.  Either chain stopping stops generation — except
    // that, with `loops`, the pitch chain starts again from the beginning, as `looping` would.
    //
    private static func _generateStates<T, P>(using chains: Model<T, P>.Chains,
                                              mixingWith others: [Model<T, P>.Chains],
                                              options: GenerationOptions<T, P>,
                                              continuing phrase: [State<T, P>],
                                              realizer: Realizer<T, P>,
                                              rng: inout SeededRandomNumberGenerator,
                                              until step: (State<T, P>) -> Bool) throws where T.DurationType: TemplateDuration {
        switch chains {
        case let .joint(markovChain):
            var generator = try _makeGenerator(using: _chains(markovChain, others, .joint),
                                               as: .joint,
                                               chainOptions: options.mainChain,
                                               options: options,
                                               realizer: realizer,
                                               rng: &rng)

            _ = generator.generate(continuing: phrase,
                                   until: step)

        case let .separate(durationChain, pitchChain):
            var durationGenerator = try _makeGenerator(using: _chains(durationChain, others, .duration),
                                                       as: .duration,
                                                       chainOptions: options.mainChain,
                                                       options: options,
                                                       realizer: realizer,
                                                       rng: &rng)

            var pitchGenerator = try _makeGenerator(using: _chains(pitchChain, others, .pitch),
                                                    as: .pitch,
                                                    chainOptions: options.pitchChain ?? options.mainChain,
                                                    options: options,
                                                    realizer: realizer,
                                                    rng: &rng)

            let historyLimit = pitchChain.maximumOrder
            var pitchHistory = Array(phrase.filter { !$0.isRest }.map(\.pitchHalf).suffix(historyLimit))

            func nextPitchHalf() -> State<T, P>? {
                if let pitchHalf = pitchGenerator.next(after: pitchHistory) {
                    return pitchHalf
                }

                guard options.loops
                else { return nil }

                pitchHistory = []

                return pitchGenerator.next(after: [])
            }

            _ = durationGenerator.generate(continuing: phrase.map(\.durationHalf)) { durationHalf in
                var pitchHalf: State<T, P>?

                if !durationHalf.isRest {
                    guard let nextHalf = nextPitchHalf()
                    else { return true }

                    pitchHistory = Array((pitchHistory + [nextHalf]).suffix(historyLimit))
                    pitchHalf = nextHalf
                }

                return step(State(durationHalf: durationHalf,
                                  pitchHalf: pitchHalf))
            }
        }
    }

    //
    // With a phrase, the chains continue its states, the realizer starts from its end, and the
    // output starts with its own note events (if it includes the phrase).  The length and cadence
    // count the continuation only.
    //
    //
    // This template's chain with `role`, then each other's.  The others share this template's state
    // recipe, so they have the same roles.
    //
    private static func _chains<T, P>(_ markovChain: MarkovChain<State<T, P>>,
                                      _ others: [Model<T, P>.Chains],
                                      _ role: ChainRole) throws -> [MarkovChain<State<T, P>>] where T.DurationType: TemplateDuration {
        var chains = [markovChain]

        for other in others {
            guard let chain = other.chain(for: role)
            else { throw Error.incompatibleTemplates }

            chains.append(chain)
        }

        return chains
    }

    private static func _generateNoteTable<T, P>(using model: Model<T, P>,
                                                 mixingWith others: [Model<T, P>],
                                                 options: GenerationOptions<T, P>,
                                                 learner: PhraseLearner<T, P>,
                                                 seed: UInt64) throws -> NoteTable<T, P> where T.DurationType: TemplateDuration {
        let isSeparated = if case .separate = model.chains { true } else { false }

        try options.validate(maximumOrder: model.chains.maximumOrder,
                             isSeparated: isSeparated)

        let topOrder = max(options.mainChain.topOrder, options.pitchChain?.topOrder ?? 0)

        guard others.count == options.templateMix?.otherTemplates.count ?? 0,
              others.allSatisfy({ $0.chains.maximumOrder >= topOrder && $0.chains.roles == model.chains.roles })
        else { throw Error.incompatibleTemplates }

        var rng = SeededRandomNumberGenerator(seed: seed)

        //
        // Drawn first, but only when it's used, so that the generators' seeds — and so what a
        // seed generates — don't depend on it otherwise.
        //
        let memberSeed = options.samplesMembers ? rng.next() : 0

        let phrase = learner.learn(options.phrase?.noteEvents ?? [])

        let realizer = Realizer(vocabulary: others.reduce(model.vocabulary) { $0.adding($1.vocabulary) },
                                options: options,
                                isRelative: learner.analysisOptions.states.isRelative,
                                phrase: phrase.noteEvents,
                                memberSeed: memberSeed)

        var noteCount = 0
        var noteEvents: [NoteEvent<T, P>] = []
        var time: T = .zero

        try _generateStates(using: model.chains,
                            mixingWith: others.map(\.chains),
                            options: options,
                            continuing: phrase.states,
                            realizer: realizer,
                            rng: &rng) { state in
            guard let noteEvent = realizer.advance(with: state)
            else { return true }

            noteEvents.append(noteEvent)

            noteCount += 1
            time = time.moved(by: DirectedDuration(duration: noteEvent.duration,
                                                   direction: .forward)).require()

            if options.length.isReached(noteCount: noteCount,
                                        time: time) {
                return true
            }

            guard let cadence = options.cadence
            else { return false }

            return cadence.matches(noteEvent) && cadence.minimumLength.isReached(noteCount: noteCount,
                                                                                 time: time)
        }

        let leadIn = options.phrase.map { $0.includesPhrase ? $0.noteEvents : [] } ?? []

        var assembler = NoteTable<T, P>.Assembler(noteEvents: leadIn + noteEvents)

        return assembler.assembleNoteTable()
    }

    private static func _generatePart<T, P>(using model: Model<T, P>,
                                            mixingWith others: [Model<T, P>],
                                            options: GenerationOptions<T, P>,
                                            analysisOptions: AnalysisOptions,
                                            grouping: @escaping ([T.DurationType]) -> [T.DurationType: T.DurationType],
                                            rounding: @escaping (P) -> P,
                                            seed: UInt64) throws -> Part<T, P> where T.DurationType: TemplateDuration {
        let partName = switch options.length {
        case let .duration(duration):
            "Generated, order: \(options.order), length: \(duration)"

        case let .noteCount(count):
            "Generated, order: \(options.order), limit: \(count)"
        }

        return try Part(name: partName,
                        noteTable: _generateNoteTable(using: model,
                                                      mixingWith: others,
                                                      options: options,
                                                      learner: PhraseLearner(analysisOptions: analysisOptions,
                                                                             vocabulary: model.vocabulary,
                                                                             grouping: grouping,
                                                                             rounding: rounding),
                                                      seed: seed))
    }

    //
    // The tolerances are the template's own, for a phrase to continue (see `PhraseLearner`).
    //
    private static func _generateWorkContent(from content: Template.Content,
                                             mixingWith others: [Template.Content],
                                             options: AnyGenerationOptions,
                                             analysisOptions: AnalysisOptions,
                                             seed: UInt64) throws -> Work.Content {
        let durations = analysisOptions.durations
        let pitches = analysisOptions.pitches

        return switch (content, options) {
        case let (.absoluteBeat(model), .absoluteBeat(options)):
            try .absoluteBeat([_generatePart(using: model,
                                             mixingWith: _models(others) { if case let .absoluteBeat(model) = $0 { model } else { nil } },
                                             options: options,
                                             analysisOptions: analysisOptions,
                                             grouping: beatGrouping(durations),
                                             rounding: frequencyRounding(pitches),
                                             seed: seed)],
                              TempoMap())

        case let (.absoluteWall(model), .absoluteWall(options)):
            try .absoluteWall([_generatePart(using: model,
                                             mixingWith: _models(others) { if case let .absoluteWall(model) = $0 { model } else { nil } },
                                             options: options,
                                             analysisOptions: analysisOptions,
                                             grouping: wallGrouping(durations),
                                             rounding: frequencyRounding(pitches),
                                             seed: seed)])

        case let (.keyboardBeat(model), .keyboardBeat(options)):
            try .keyboardBeat([_generatePart(using: model,
                                             mixingWith: _models(others) { if case let .keyboardBeat(model) = $0 { model } else { nil } },
                                             options: options,
                                             analysisOptions: analysisOptions,
                                             grouping: beatGrouping(durations),
                                             rounding: exactRounding(pitches),
                                             seed: seed)],
                              TempoMap())

        case let (.keyboardWall(model), .keyboardWall(options)):
            try .keyboardWall([_generatePart(using: model,
                                             mixingWith: _models(others) { if case let .keyboardWall(model) = $0 { model } else { nil } },
                                             options: options,
                                             analysisOptions: analysisOptions,
                                             grouping: wallGrouping(durations),
                                             rounding: exactRounding(pitches),
                                             seed: seed)])

        case let (.standardBeat(model), .standardBeat(options)):
            try .standardBeat([_generatePart(using: model,
                                             mixingWith: _models(others) { if case let .standardBeat(model) = $0 { model } else { nil } },
                                             options: options,
                                             analysisOptions: analysisOptions,
                                             grouping: beatGrouping(durations),
                                             rounding: exactRounding(pitches),
                                             seed: seed)],
                              TempoMap())

        case let (.standardWall(model), .standardWall(options)):
            try .standardWall([_generatePart(using: model,
                                             mixingWith: _models(others) { if case let .standardWall(model) = $0 { model } else { nil } },
                                             options: options,
                                             analysisOptions: analysisOptions,
                                             grouping: wallGrouping(durations),
                                             rounding: exactRounding(pitches),
                                             seed: seed)])

        default:
            throw Error.incompatibleOptions
        }
    }

    // MARK: Private Instance Methods

    //
    // The templates `options` mixes in, in the mix's order, from among `others`.  Each must share
    // this template's pitch notation, time basis and state recipe.
    //
    private func _mixedTemplates(for options: AnyGenerationOptions,
                                 among others: [Template]) throws(Error) -> [Template] {
        var result: [Template] = []

        for templateID in options.otherTemplates.map(\.templateID) {
            guard let other = others.first(where: { $0.templateID == templateID })
            else { throw Error.templateNotFound(templateID) }

            guard other.pitchNotation == pitchNotation,
                  other.timeBasis == timeBasis,
                  other.analysisOptions.states == analysisOptions.states
            else { throw Error.incompatibleTemplates }

            result.append(other)
        }

        return result
    }

    private func _defaultOptions(order: Int,
                                 limit: Int) -> AnyGenerationOptions {
        switch content {
        case .absoluteBeat:
            .absoluteBeat(GenerationOptions(order: order,
                                            length: .noteCount(limit)))

        case .absoluteWall:
            .absoluteWall(GenerationOptions(order: order,
                                            length: .noteCount(limit)))

        case .keyboardBeat:
            .keyboardBeat(GenerationOptions(order: order,
                                            length: .noteCount(limit)))

        case .keyboardWall:
            .keyboardWall(GenerationOptions(order: order,
                                            length: .noteCount(limit)))

        case .standardBeat:
            .standardBeat(GenerationOptions(order: order,
                                            length: .noteCount(limit)))

        case .standardWall:
            .standardWall(GenerationOptions(order: order,
                                            length: .noteCount(limit)))
        }
    }
}
