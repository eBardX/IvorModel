public import IvorTiming
public import IvorTuning
public import XestiMarkov

extension Template {
    public enum Content {
        case absoluteBeat(MarkovChain<NoteEvent<BeatTime, Frequency>>)
        case absoluteWall(MarkovChain<NoteEvent<WallTime, Frequency>>)
        case keyboardBeat(MarkovChain<NoteEvent<BeatTime, NoteNumber>>)
        case keyboardWall(MarkovChain<NoteEvent<WallTime, NoteNumber>>)
        case standardBeat(MarkovChain<NoteEvent<BeatTime, Pitch>>)
        case standardWall(MarkovChain<NoteEvent<WallTime, Pitch>>)
    }
}

// MARK: -

extension Template.Content {

    // MARK: Public Instance Properties

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
