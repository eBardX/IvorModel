// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Template {
    /// The analysis data of a template — its ``Template/Model`` — at the template’s pitch notation and
    /// time basis.
    public enum Content {
        /// Beat-time analysis data using absolute (frequency) pitch notation.
        case absoluteBeat(Model<BeatTime, Frequency>)

        /// Wall-time analysis data using absolute (frequency) pitch notation.
        case absoluteWall(Model<WallTime, Frequency>)

        /// Beat-time analysis data using keyboard (MIDI note number) pitch notation.
        case keyboardBeat(Model<BeatTime, NoteNumber>)

        /// Wall-time analysis data using keyboard (MIDI note number) pitch notation.
        case keyboardWall(Model<WallTime, NoteNumber>)

        /// Beat-time analysis data using standard (staff) pitch notation.
        case standardBeat(Model<BeatTime, Pitch>)

        /// Wall-time analysis data using standard (staff) pitch notation.
        case standardWall(Model<WallTime, Pitch>)
    }
}

// MARK: -

extension Template.Content {

    // MARK: Internal Instance Properties

    internal var pitchNotation: PitchNotation {
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

    internal var timeBasis: TimeBasis {
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

extension Template.Content: Codable {

    // MARK: Public Initializers

    /// Creates a template content value by decoding from the provided decoder.
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
            self = try .absoluteBeat(container.decode(Template.Model<BeatTime, Frequency>.self,
                                                      forKey: .model))

        case (.absolute, .wall):
            self = try .absoluteWall(container.decode(Template.Model<WallTime, Frequency>.self,
                                                      forKey: .model))

        case (.keyboard, .beat):
            self = try .keyboardBeat(container.decode(Template.Model<BeatTime, NoteNumber>.self,
                                                      forKey: .model))

        case (.keyboard, .wall):
            self = try .keyboardWall(container.decode(Template.Model<WallTime, NoteNumber>.self,
                                                      forKey: .model))

        case (.standard, .beat):
            self = try .standardBeat(container.decode(Template.Model<BeatTime, Pitch>.self,
                                                      forKey: .model))

        case (.standard, .wall):
            self = try .standardWall(container.decode(Template.Model<WallTime, Pitch>.self,
                                                      forKey: .model))
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this template content into the provided encoder.
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
        case let .absoluteBeat(model):
            try container.encode(model,
                                 forKey: .model)

        case let .absoluteWall(model):
            try container.encode(model,
                                 forKey: .model)

        case let .keyboardBeat(model):
            try container.encode(model,
                                 forKey: .model)

        case let .keyboardWall(model):
            try container.encode(model,
                                 forKey: .model)

        case let .standardBeat(model):
            try container.encode(model,
                                 forKey: .model)

        case let .standardWall(model):
            try container.encode(model,
                                 forKey: .model)
        }
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case model
        case pitchNotation
        case timeBasis
    }
}

// MARK: - Sendable

extension Template.Content: Sendable {
}
