// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Template {

    // MARK: Public Nested Types

    /// A generation recipe whose time and pitch types are chosen at run time, parameterized by
    /// pitch notation and time basis like ``Template/Content``.
    public enum AnyGenerationOptions {
        /// A recipe for a beat-time template using absolute (frequency) pitch notation.
        case absoluteBeat(GenerationOptions<BeatTime, Frequency>)

        /// A recipe for a wall-time template using absolute (frequency) pitch notation.
        case absoluteWall(GenerationOptions<WallTime, Frequency>)

        /// A recipe for a beat-time template using keyboard (MIDI note number) pitch notation.
        case keyboardBeat(GenerationOptions<BeatTime, NoteNumber>)

        /// A recipe for a wall-time template using keyboard (MIDI note number) pitch notation.
        case keyboardWall(GenerationOptions<WallTime, NoteNumber>)

        /// A recipe for a beat-time template using standard (staff) pitch notation.
        case standardBeat(GenerationOptions<BeatTime, Pitch>)

        /// A recipe for a wall-time template using standard (staff) pitch notation.
        case standardWall(GenerationOptions<WallTime, Pitch>)
    }
}

// MARK: -

extension Template.AnyGenerationOptions {

    // MARK: Public Initializers

    /// Creates a recipe from a typed one, or returns `nil` if its time and pitch types are not
    /// those of any pitch notation and time basis.
    ///
    /// - Parameter options:    The typed recipe.
    public init?(_ options: Template.GenerationOptions<some Any, some Any>) {
        switch options {
        case let options as Template.GenerationOptions<BeatTime, Frequency>:
            self = .absoluteBeat(options)

        case let options as Template.GenerationOptions<WallTime, Frequency>:
            self = .absoluteWall(options)

        case let options as Template.GenerationOptions<BeatTime, NoteNumber>:
            self = .keyboardBeat(options)

        case let options as Template.GenerationOptions<WallTime, NoteNumber>:
            self = .keyboardWall(options)

        case let options as Template.GenerationOptions<BeatTime, Pitch>:
            self = .standardBeat(options)

        case let options as Template.GenerationOptions<WallTime, Pitch>:
            self = .standardWall(options)

        default:
            return nil
        }
    }

    // MARK: Public Instance Properties

    /// The pitch notation of templates this recipe applies to.
    public var pitchNotation: PitchNotation {
        switch self {
        case .absoluteBeat,
             .absoluteWall:
            .absolute

        case .keyboardBeat,
             .keyboardWall:
            .keyboard

        case .standardBeat,
             .standardWall:
            .standard
        }
    }

    /// The time basis of templates this recipe applies to.
    public var timeBasis: TimeBasis {
        switch self {
        case .absoluteBeat,
             .keyboardBeat,
             .standardBeat:
            .beat

        case .absoluteWall,
             .keyboardWall,
             .standardWall:
            .wall
        }
    }
}

// MARK: - Codable

extension Template.AnyGenerationOptions: Codable {

    // MARK: Public Initializers

    /// Creates a recipe by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let pitchNotation = try container.decode(PitchNotation.self,
                                                 forKey: .pitchNotation)

        let timeBasis = try container.decode(TimeBasis.self,
                                             forKey: .timeBasis)

        switch (pitchNotation, timeBasis) {
        case (.absolute, .beat):
            self = try .absoluteBeat(container.decode(Template.GenerationOptions<BeatTime, Frequency>.self,
                                                      forKey: .options))

        case (.absolute, .wall):
            self = try .absoluteWall(container.decode(Template.GenerationOptions<WallTime, Frequency>.self,
                                                      forKey: .options))

        case (.keyboard, .beat):
            self = try .keyboardBeat(container.decode(Template.GenerationOptions<BeatTime, NoteNumber>.self,
                                                      forKey: .options))

        case (.keyboard, .wall):
            self = try .keyboardWall(container.decode(Template.GenerationOptions<WallTime, NoteNumber>.self,
                                                      forKey: .options))

        case (.standard, .beat):
            self = try .standardBeat(container.decode(Template.GenerationOptions<BeatTime, Pitch>.self,
                                                      forKey: .options))

        case (.standard, .wall):
            self = try .standardWall(container.decode(Template.GenerationOptions<WallTime, Pitch>.self,
                                                      forKey: .options))
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this recipe into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(pitchNotation,
                             forKey: .pitchNotation)

        try container.encode(timeBasis,
                             forKey: .timeBasis)

        switch self {
        case let .absoluteBeat(options):
            try container.encode(options,
                                 forKey: .options)

        case let .absoluteWall(options):
            try container.encode(options,
                                 forKey: .options)

        case let .keyboardBeat(options):
            try container.encode(options,
                                 forKey: .options)

        case let .keyboardWall(options):
            try container.encode(options,
                                 forKey: .options)

        case let .standardBeat(options):
            try container.encode(options,
                                 forKey: .options)

        case let .standardWall(options):
            try container.encode(options,
                                 forKey: .options)
        }
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case options
        case pitchNotation
        case timeBasis
    }
}

// MARK: - Hashable

extension Template.AnyGenerationOptions: Hashable {
}

// MARK: - Sendable

extension Template.AnyGenerationOptions: Sendable {
}
