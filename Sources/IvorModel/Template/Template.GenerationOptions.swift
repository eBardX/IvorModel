// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Template {

    // MARK: Public Nested Types

    /// A recipe for generating a work from a template.
    ///
    /// The time and pitch types must match the template’s content; see
    /// ``Template/AnyGenerationOptions`` for a recipe whose types are chosen at run time. The
    /// defaults reproduce the plain generation of earlier versions: order 1, at most 100 note
    /// events, starting at the source’s opening and stopping where it ends.
    ///
    /// The options are applied in this order: ``mixing`` (or ``order`` alone), then
    /// ``constraints``, then ``contrast``, then ``backsOff``, then ``loops``. Generation stops
    /// when ``length`` is reached, or at the ``cadence`` once its minimum length is reached,
    /// whichever comes first; it may also stop earlier, at the end of a source sequence or at a
    /// dead end, unless ``stopsAtEnd`` is `false` or ``backsOff`` is `true`.
    public struct GenerationOptions<TimeType: TimeProtocol, PitchType: PitchProtocol> {

        // MARK: Public Initializers

        /// Creates a new generation recipe.
        ///
        /// - Parameter order:          The Markov order to generate at. Defaults to 1.
        /// - Parameter length:         When to stop generating. Defaults to 100 note events.
        /// - Parameter startsAtBegin:  Whether generation begins at the source’s opening.
        ///                             Defaults to `true`.
        /// - Parameter stopsAtEnd:     Whether generation can stop where the source ends.
        ///                             Defaults to `true`.
        /// - Parameter backsOff:       Whether to fall back to lower orders at a dead end.
        ///                             Defaults to `false`.
        /// - Parameter loops:          Whether to restart when generation would stop early.
        ///                             Defaults to `false`.
        /// - Parameter contrast:       How strongly to favour common paths. Defaults to 1.
        /// - Parameter constraints:    Which note events may be generated. Defaults to no
        ///                             constraints.
        /// - Parameter mixing:         How to mix ``order`` with another order. Defaults to `nil`.
        /// - Parameter cadence:        A note event on which to end. Defaults to `nil`.
        public init(order: Int = 1,
                    length: Length = .noteCount(100),
                    startsAtBegin: Bool = true,
                    stopsAtEnd: Bool = true,
                    backsOff: Bool = false,
                    loops: Bool = false,
                    contrast: Double = 1,
                    constraints: Constraints = Constraints(),
                    mixing: Mixing? = nil,
                    cadence: Cadence? = nil) {
            self.backsOff = backsOff
            self.cadence = cadence
            self.constraints = constraints
            self.contrast = contrast
            self.length = length
            self.loops = loops
            self.mixing = mixing
            self.order = order
            self.startsAtBegin = startsAtBegin
            self.stopsAtEnd = stopsAtEnd
        }

        // MARK: Public Instance Properties

        /// Whether to fall back to successively lower orders, down to order 0, when generation
        /// at the current order can’t continue — at a dead end, or when the end of a source
        /// sequence is chosen. Order 0 never ends, so with this set, only ``length`` or
        /// ``cadence`` stop generation.
        public var backsOff: Bool

        /// A note event on which to end, once a minimum length has been generated, or `nil`.
        public var cadence: Cadence?

        /// Which note events may be generated.
        public var constraints: Constraints

        /// How strongly to favour common paths: above 1 keeps to common paths, below 1 favours
        /// rare ones, and 1 leaves the template’s probabilities unchanged. Must be positive and
        /// finite.
        public var contrast: Double

        /// When to stop generating.
        public var length: Length

        /// Whether to restart from the beginning (or, if ``startsAtBegin`` is `false`, from
        /// anywhere) whenever generation would otherwise stop before ``length``.
        public var loops: Bool

        /// How to mix ``order`` with another order, or `nil` to generate at ``order`` alone.
        public var mixing: Mixing?

        /// The Markov order to generate at: the number of preceding note events that choose the
        /// next. Must be between 0 and the template’s maximum order.
        public var order: Int

        /// Whether generation begins at the source’s opening. When `false`, the first note
        /// event is chosen by how often it occurs in the source, so generation can start
        /// anywhere.
        public var startsAtBegin: Bool

        /// Whether generation can stop where a source sequence ends. When `false`, the end is
        /// never chosen, and generation continues until ``length`` (or ``cadence``) stops it.
        public var stopsAtEnd: Bool
    }
}

// MARK: -

extension Template.GenerationOptions {

    // MARK: Public Type Aliases

    /// The duration type associated with the time type.
    public typealias DurationType = TimeType.DurationType

    // MARK: Internal Instance Properties

    //
    // The highest order the recipe generates at, from which back-off descends.
    //
    internal var topOrder: Int {
        switch mixing {
        case let .blend(otherOrder, _),
             let .morph(otherOrder, _, _):
            max(order, otherOrder)

        case nil:
            order
        }
    }

    // MARK: Internal Instance Methods

    internal func validate(maximumOrder: Int) throws(Template.Error) {
        guard (0...maximumOrder) ~= order
        else { throw .invalidOrder(maximumOrder) }

        guard length.isValid
        else { throw .invalidLimit }

        guard contrast.isFinite,
              contrast > 0
        else { throw .invalidContrast }

        try mixing?.validate(maximumOrder: maximumOrder)

        if let cadence {
            guard cadence.minimumLength.isValid
            else { throw .invalidLimit }
        }
    }
}

// MARK: - Codable

extension Template.GenerationOptions: Codable {
}

// MARK: - Hashable

extension Template.GenerationOptions: Hashable {
}

// MARK: - Sendable

extension Template.GenerationOptions: Sendable {
}
