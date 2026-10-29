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
        try Work(name: name,
                 content: Self._generateWorkContent(from: content,
                                                    options: options,
                                                    isRelative: analysisOptions.states.isRelative,
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
    // Builds the generator stack, in the order documented on `GenerationOptions`: mixing (or
    // the order alone), then constraints, then contrast, then back-off, then looping. Every
    // sampling generator gets its own seed, drawn in a fixed order from one generator seeded
    // with `seed`, so the whole stack is reproducible.
    //
    // Constraints test realized note events (see `Realizer`), and so does the range that a
    // relative recipe keeps to.  When the range rules out every choice, a fallback at the
    // recipe's order, under the constraints alone, chooses instead, and the realizer brings the
    // result back into range.
    //
    private static func _makeGenerator<T, P>(using markovChain: MarkovChain<State<T, P>>,
                                             options: GenerationOptions<T, P>,
                                             realizer: Realizer<T, P>,
                                             rng: inout SeededRandomNumberGenerator) throws -> any MarkovChain<State<T, P>>.Generator
        where T.DurationType: TemplateDuration {
        typealias Chain = MarkovChain<State<T, P>>

        func makeSimple(order: Int,
                        rng: inout SeededRandomNumberGenerator) throws -> any Chain.Generator {
            guard let generator = markovChain.generator(order: order,
                                                        startsAtBegin: options.startsAtBegin,
                                                        stopsAtEnd: options.stopsAtEnd,
                                                        using: SeededRandomNumberGenerator(seed: rng.next()))
            else { throw Error.invalidOrder(markovChain.maximumOrder) }

            return generator
        }

        func decorate(_ generator: any Chain.Generator,
                      checkingRange: Bool,
                      rng: inout SeededRandomNumberGenerator) -> any Chain.Generator {
            var result = generator

            if !options.constraints.isEmpty || (checkingRange && realizer.range != nil) {
                result = Chain.generator(filtering: result,
                                         where: { realizer.allows($0, checkingRange: checkingRange) },
                                         using: SeededRandomNumberGenerator(seed: rng.next()))
            }

            if options.contrast != 1 {
                result = Chain.generator(contrasting: result,
                                         by: options.contrast,
                                         using: SeededRandomNumberGenerator(seed: rng.next()))
            }

            return result
        }

        let primary: any Chain.Generator = switch options.mixing {
        case let .blend(otherOrder, weight):
            try Chain.generator(blending: [(makeSimple(order: options.order, rng: &rng), weight: 1 - weight),
                                           (makeSimple(order: otherOrder, rng: &rng), weight: weight)],
                                using: SeededRandomNumberGenerator(seed: rng.next()))

        case let .morph(otherOrder, steps, curve):
            try Chain.generator(interpolating: makeSimple(order: options.order, rng: &rng),
                                to: makeSimple(order: otherOrder, rng: &rng),
                                over: steps,
                                along: _CurveInterpolator(curve: curve),
                                using: SeededRandomNumberGenerator(seed: rng.next()))

        case nil:
            try makeSimple(order: options.order, rng: &rng)
        }

        var stack = decorate(primary,
                             checkingRange: true,
                             rng: &rng)

        if options.backsOff {
            for order in (0..<options.topOrder).reversed() {
                stack = try Chain.generator(trying: stack,
                                            otherwise: decorate(makeSimple(order: order, rng: &rng),
                                                                checkingRange: true,
                                                                rng: &rng))
            }
        }

        if realizer.range != nil {
            stack = try Chain.generator(trying: stack,
                                        otherwise: decorate(makeSimple(order: options.order, rng: &rng),
                                                            checkingRange: false,
                                                            rng: &rng))
        }

        if options.loops {
            stack = Chain.generator(looping: stack)
        }

        return stack
    }

    private static func _generateNoteTable<T, P>(using model: Model<T, P>,
                                                 options: GenerationOptions<T, P>,
                                                 isRelative: Bool,
                                                 seed: UInt64) throws -> NoteTable<T, P> where T.DurationType: TemplateDuration {
        try options.validate(maximumOrder: model.markovChain.maximumOrder)

        var rng = SeededRandomNumberGenerator(seed: seed)

        //
        // Drawn first, but only when it's used, so that the generators' seeds — and so what a
        // seed generates — don't depend on it otherwise.
        //
        let memberSeed = options.samplesMembers ? rng.next() : 0

        let realizer = Realizer(vocabulary: model.vocabulary,
                                options: options,
                                isRelative: isRelative,
                                memberSeed: memberSeed)

        var generator = try _makeGenerator(using: model.markovChain,
                                           options: options,
                                           realizer: realizer,
                                           rng: &rng)

        var noteCount = 0
        var noteEvents: [NoteEvent<T, P>] = []
        var time: T = .zero

        _ = generator.generate { state in
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

        var assembler = NoteTable<T, P>.Assembler(noteEvents: noteEvents)

        return assembler.assembleNoteTable()
    }

    private static func _generatePart<T, P>(using model: Model<T, P>,
                                            options: GenerationOptions<T, P>,
                                            isRelative: Bool,
                                            seed: UInt64) throws -> Part<T, P> where T.DurationType: TemplateDuration {
        let partName = switch options.length {
        case let .duration(duration):
            "Generated, order: \(options.order), length: \(duration)"

        case let .noteCount(count):
            "Generated, order: \(options.order), limit: \(count)"
        }

        return try Part(name: partName,
                        noteTable: _generateNoteTable(using: model,
                                                      options: options,
                                                      isRelative: isRelative,
                                                      seed: seed))
    }

    private static func _generateWorkContent(from content: Template.Content,
                                             options: AnyGenerationOptions,
                                             isRelative: Bool,
                                             seed: UInt64) throws -> Work.Content {
        switch (content, options) {
        case let (.absoluteBeat(model), .absoluteBeat(options)):
            try .absoluteBeat([_generatePart(using: model,
                                             options: options,
                                             isRelative: isRelative,
                                             seed: seed)],
                              TempoMap())

        case let (.absoluteWall(model), .absoluteWall(options)):
            try .absoluteWall([_generatePart(using: model,
                                             options: options,
                                             isRelative: isRelative,
                                             seed: seed)])

        case let (.keyboardBeat(model), .keyboardBeat(options)):
            try .keyboardBeat([_generatePart(using: model,
                                             options: options,
                                             isRelative: isRelative,
                                             seed: seed)],
                              TempoMap())

        case let (.keyboardWall(model), .keyboardWall(options)):
            try .keyboardWall([_generatePart(using: model,
                                             options: options,
                                             isRelative: isRelative,
                                             seed: seed)])

        case let (.standardBeat(model), .standardBeat(options)):
            try .standardBeat([_generatePart(using: model,
                                             options: options,
                                             isRelative: isRelative,
                                             seed: seed)],
                              TempoMap())

        case let (.standardWall(model), .standardWall(options)):
            try .standardWall([_generatePart(using: model,
                                             options: options,
                                             isRelative: isRelative,
                                             seed: seed)])

        default:
            throw Error.incompatibleOptions
        }
    }

    // MARK: Private Instance Methods

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
