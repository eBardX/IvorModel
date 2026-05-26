// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiMarkov

extension Template {
    /// The analysis data of a template, parameterized by pitch notation and time basis.
    public enum Content {
        /// Beat-time analysis data using absolute (frequency) pitch notation.
        case absoluteBeat(MarkovChain<NoteEvent<BeatTime, Frequency>>)

        /// Wall-time analysis data using absolute (frequency) pitch notation.
        case absoluteWall(MarkovChain<NoteEvent<WallTime, Frequency>>)

        /// Beat-time analysis data using keyboard (MIDI note number) pitch notation.
        case keyboardBeat(MarkovChain<NoteEvent<BeatTime, NoteNumber>>)

        /// Wall-time analysis data using keyboard (MIDI note number) pitch notation.
        case keyboardWall(MarkovChain<NoteEvent<WallTime, NoteNumber>>)

        /// Beat-time analysis data using standard (staff) pitch notation.
        case standardBeat(MarkovChain<NoteEvent<BeatTime, Pitch>>)

        /// Wall-time analysis data using standard (staff) pitch notation.
        case standardWall(MarkovChain<NoteEvent<WallTime, Pitch>>)
    }
}

// MARK: -

extension Template.Content {

    // MARK: Public Instance Properties

    /// The maximum pattern depth supported by this content.
    public var maximumOrder: Int {
        switch self {
        case let .absoluteBeat(markovChain):
            markovChain.maximumOrder

        case let .absoluteWall(markovChain):
            markovChain.maximumOrder

        case let .keyboardBeat(markovChain):
            markovChain.maximumOrder
//

        case let .keyboardWall(markovChain):
            markovChain.maximumOrder

        case let .standardBeat(markovChain):
            markovChain.maximumOrder

        case let .standardWall(markovChain):
            markovChain.maximumOrder
        }
    }

    /// The pitch notation used by this content.
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

    /// The time basis used by this content.
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
            self = try .absoluteBeat(container.decode(MarkovChain<NoteEvent<BeatTime, Frequency>>.self,
                                                      forKey: .markovChain))

        case (.absolute, .wall):
            self = try .absoluteWall(container.decode(MarkovChain<NoteEvent<WallTime, Frequency>>.self,
                                                      forKey: .markovChain))

        case (.keyboard, .beat):
            self = try .keyboardBeat(container.decode(MarkovChain<NoteEvent<BeatTime, NoteNumber>>.self,
                                                      forKey: .markovChain))

        case (.keyboard, .wall):
            self = try .keyboardWall(container.decode(MarkovChain<NoteEvent<WallTime, NoteNumber>>.self,
                                                      forKey: .markovChain))

        case (.standard, .beat):
            self = try .standardBeat(container.decode(MarkovChain<NoteEvent<BeatTime, Pitch>>.self,
                                                      forKey: .markovChain))

        case (.standard, .wall):
            self = try .standardWall(container.decode(MarkovChain<NoteEvent<WallTime, Pitch>>.self,
                                                      forKey: .markovChain))
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
        case let .absoluteBeat(markovChain):
            try container.encode(markovChain,
                                 forKey: .markovChain)

        case let .absoluteWall(markovChain):
            try container.encode(markovChain,
                                 forKey: .markovChain)

        case let .keyboardBeat(markovChain):
            try container.encode(markovChain,
                                 forKey: .markovChain)

        case let .keyboardWall(markovChain):
            try container.encode(markovChain,
                                 forKey: .markovChain)

        case let .standardBeat(markovChain):
            try container.encode(markovChain,
                                 forKey: .markovChain)

        case let .standardWall(markovChain):
            try container.encode(markovChain,
                                 forKey: .markovChain)
        }
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case markovChain
        case pitchNotation
        case timeBasis
    }
}

// MARK: - Sendable

extension Template.Content: Sendable {
}
