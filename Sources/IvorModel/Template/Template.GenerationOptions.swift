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
    /// ``constraints``, then ``contrast``, then ``backsOff``, then ``loops``. A template that
    /// separates pitch and duration generates from its two chains in step: the duration chain
    /// chooses each event’s duration and whether it is a rest, and the pitch chain chooses the
    /// pitches of each sounding event. Each chain gets its own stack of generators, so back-off
    /// and looping apply to each chain on its own, and either chain stopping stops generation. Generation stops
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
        /// - Parameter startPitch:     The pitch that relative states start from. Defaults to
        ///                             `nil`.
        /// - Parameter startDuration:  The duration that relative states start from. Defaults to
        ///                             `nil`.
        /// - Parameter samplesMembers: Whether to draw grouped values from their members.
        ///                             Defaults to `false`.
        /// - Parameter pitchChain:     How to generate from a separated template’s pitch chain.
        ///                             Defaults to `nil` (the same as its duration chain).
        public init(order: Int = 1,
                    length: Length = .noteCount(100),
                    startsAtBegin: Bool = true,
                    stopsAtEnd: Bool = true,
                    backsOff: Bool = false,
                    loops: Bool = false,
                    contrast: Double = 1,
                    constraints: Constraints = Constraints(),
                    mixing: Mixing? = nil,
                    cadence: Cadence? = nil,
                    startPitch: PitchType? = nil,
                    startDuration: TimeType.DurationType? = nil,
                    samplesMembers: Bool = false,
                    pitchChain: ChainOptions? = nil) {
            self.backsOff = backsOff
            self.cadence = cadence
            self.constraints = constraints
            self.contrast = contrast
            self.length = length
            self.loops = loops
            self.mixing = mixing
            self.order = order
            self.pitchChain = pitchChain
            self.samplesMembers = samplesMembers
            self.startDuration = startDuration
            self.startPitch = startPitch
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

        /// How to generate from a separated template’s pitch chain, or `nil` to use ``order``,
        /// ``mixing`` and ``contrast``, as its duration chain does. Must be `nil` for a template
        /// with one joint chain.
        public var pitchChain: ChainOptions?

        /// Whether to replace each pitch and duration that an analysis tolerance grouped with one
        /// of the values it grouped, drawn in proportion to how often each occurred — keeping the
        /// source’s nuances while the template works with the groups. Applies only where the
        /// template records absolute pitches or durations.
        public var samplesMembers: Bool

        /// The duration that relative durations start from, and the duration of every event when
        /// the template records none; or `nil` for the source’s first duration (or, when it
        /// records none, its most common one). Must not be zero.
        public var startDuration: TimeType.DurationType?

        /// The pitch that intervals and pitch classes start from, and the pitch of every sounding
        /// event when the template records none; or `nil` for the source’s first bass (or, when it
        /// records none, its most common pitch).
        public var startPitch: PitchType?

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
    // The order, mixing and contrast of a joint template's chain, or a separated template's
    // duration chain.
    //
    internal var mainChain: ChainOptions {
        ChainOptions(order: order,
                     mixing: mixing,
                     contrast: contrast)
    }

    // MARK: Internal Instance Methods

    //
    // `isSeparated` is whether the template separates pitch and duration: only then may
    // `pitchChain` be set.
    //
    internal func validate(maximumOrder: Int,
                           isSeparated: Bool) throws(Template.Error) {
        guard isSeparated || pitchChain == nil
        else { throw .incompatibleOptions }

        try mainChain.validate(maximumOrder: maximumOrder)
        try pitchChain?.validate(maximumOrder: maximumOrder)

        guard length.isValid
        else { throw .invalidLimit }

        if let cadence {
            guard cadence.minimumLength.isValid
            else { throw .invalidLimit }
        }

        if let startDuration {
            guard !startDuration.isZero
            else { throw .invalidLimit }
        }
    }
}

// MARK: - Codable

extension Template.GenerationOptions: Codable {

    // MARK: Public Initializers

    /// Creates a generation recipe by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.backsOff = try container.decode(Bool.self, forKey: .backsOff)
        self.cadence = try container.decodeIfPresent(Cadence.self, forKey: .cadence)
        self.constraints = try container.decode(Constraints.self, forKey: .constraints)
        self.contrast = try container.decode(Double.self, forKey: .contrast)
        self.length = try container.decode(Length.self, forKey: .length)
        self.loops = try container.decode(Bool.self, forKey: .loops)
        self.mixing = try container.decodeIfPresent(Mixing.self, forKey: .mixing)
        self.order = try container.decode(Int.self, forKey: .order)
        self.pitchChain = try container.decodeIfPresent(ChainOptions.self, forKey: .pitchChain)
        self.samplesMembers = try container.decode(Bool.self, forKey: .samplesMembers)
        self.startDuration = try container.decodeIfPresent(DurationType.self, forKey: .startDuration)
        self.startPitch = try container.decodeIfPresent(PitchType.self, forKey: .startPitch)
        self.startsAtBegin = try container.decode(Bool.self, forKey: .startsAtBegin)
        self.stopsAtEnd = try container.decode(Bool.self, forKey: .stopsAtEnd)
    }

    // MARK: Public Instance Methods

    /// Encodes this generation recipe into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(backsOff, forKey: .backsOff)
        try container.encodeIfPresent(cadence, forKey: .cadence)
        try container.encode(constraints, forKey: .constraints)
        try container.encode(contrast, forKey: .contrast)
        try container.encode(length, forKey: .length)
        try container.encode(loops, forKey: .loops)
        try container.encodeIfPresent(mixing, forKey: .mixing)
        try container.encode(order, forKey: .order)
        try container.encodeIfPresent(pitchChain, forKey: .pitchChain)
        try container.encode(samplesMembers, forKey: .samplesMembers)
        try container.encodeIfPresent(startDuration, forKey: .startDuration)
        try container.encodeIfPresent(startPitch, forKey: .startPitch)
        try container.encode(startsAtBegin, forKey: .startsAtBegin)
        try container.encode(stopsAtEnd, forKey: .stopsAtEnd)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case backsOff
        case cadence
        case constraints
        case contrast
        case length
        case loops
        case mixing
        case order
        case pitchChain
        case samplesMembers
        case startDuration
        case startPitch
        case startsAtBegin
        case stopsAtEnd
    }
}

// MARK: - Hashable

extension Template.GenerationOptions: Hashable {
}

// MARK: - Sendable

extension Template.GenerationOptions: Sendable {
}
