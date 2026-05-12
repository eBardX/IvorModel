public import IvorTiming
public import IvorTuning

extension Work {
    public enum Content {
        case absoluteBeat([Part<BeatTime, Frequency>], TempoMap)
        case absoluteWall([Part<WallTime, Frequency>])
        case keyboardBeat([Part<BeatTime, NoteNumber>], TempoMap)
        case keyboardWall([Part<WallTime, NoteNumber>])
        case standardBeat([Part<BeatTime, Pitch>], TempoMap)
        case standardWall([Part<WallTime, Pitch>])
    }
}

// MARK: -

extension Work.Content {

    // MARK: Public Instance Properties

    public var beatTimeRange: ClosedRange<BeatTime>? {
        switch self {
        case let .absoluteBeat(parts, _):
            Self._determineTimeRange(of: parts)

        case let .keyboardBeat(parts, _):
            Self._determineTimeRange(of: parts)

        case let .standardBeat(parts, _):
            Self._determineTimeRange(of: parts)

        default:
            nil
        }
    }

    public var partCount: Int {
        switch self {
        case let .absoluteBeat(parts, _):
            parts.count

        case let .absoluteWall(parts):
            parts.count

        case let .keyboardBeat(parts, _):
            parts.count

        case let .keyboardWall(parts):
            parts.count

        case let .standardBeat(parts, _):
            parts.count

        case let .standardWall(parts):
            parts.count
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

    public var tempoMap: TempoMap? {
        switch self {
        case let .absoluteBeat(_, tmap),
            let .keyboardBeat(_, tmap),
            let .standardBeat(_, tmap):
            tmap

        default:
            nil
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

    public var wallTimeRange: ClosedRange<WallTime>? {
        switch self {
        case let .absoluteWall(parts):
            Self._determineTimeRange(of: parts)

        case let .keyboardWall(parts):
            Self._determineTimeRange(of: parts)

        case let .standardWall(parts):
            Self._determineTimeRange(of: parts)

        default:
            nil
        }
    }

    // MARK: Public Instance Methods

    public func partName(at index: Int) -> String {
        switch self {
        case let .absoluteBeat(parts, _):
            parts[index].name

        case let .absoluteWall(parts):
            parts[index].name

        case let .keyboardBeat(parts, _):
            parts[index].name

        case let .keyboardWall(parts):
            parts[index].name

        case let .standardBeat(parts, _):
            parts[index].name

        case let .standardWall(parts):
            parts[index].name
        }
    }

    // MARK: Private Type Methods

    private static func _determineTimeRange<TimeType: TimeProtocol>(of parts: [Part<TimeType, some PitchProtocol>]) -> ClosedRange<TimeType> {
        guard !parts.isEmpty
        else { return TimeType.zero...TimeType.zero }

        var timeRange = parts[0].timeRange

        for part in parts {
            let trange = part.timeRange
            let hiTime = max(timeRange.upperBound,
                             trange.upperBound)
            let loTime = min(timeRange.lowerBound,
                             trange.lowerBound)

            timeRange = loTime...hiTime
        }

        return timeRange
    }
}

// MARK: - Codable

extension Work.Content: Codable {

    // MARK: Public Initializers

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let pitchNotation = try container.decode(PitchNotation.self,
                                                 forKey: .pitchNotation)

        let timeBasis = try container.decode(TimeBasis.self,
                                             forKey: .timeBasis)

        switch (pitchNotation, timeBasis) {
        case (.absolute, .beat):
            self = try .absoluteBeat(container.decode([Part<BeatTime, Frequency>].self,
                                                      forKey: .parts),
                                     container.decode(TempoMap.self,
                                                      forKey: .tempoMap))

        case (.absolute, .wall):
            self = try .absoluteWall(container.decode([Part<WallTime, Frequency>].self,
                                                      forKey: .parts))

        case (.keyboard, .beat):
            self = try .keyboardBeat(container.decode([Part<BeatTime, NoteNumber>].self,
                                                      forKey: .parts),
                                     container.decode(TempoMap.self,
                                                      forKey: .tempoMap))

        case (.keyboard, .wall):
            self = try .keyboardWall(container.decode([Part<WallTime, NoteNumber>].self,
                                                      forKey: .parts))

        case (.standard, .beat):
            self = try .standardBeat(container.decode([Part<BeatTime, Pitch>].self,
                                                      forKey: .parts),
                                     container.decode(TempoMap.self,
                                                      forKey: .tempoMap))

        case (.standard, .wall):
            self = try .standardWall(container.decode([Part<WallTime, Pitch>].self,
                                                      forKey: .parts))
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
        case let .absoluteBeat(parts, tempoMap):
            try container.encode(parts,
                                 forKey: .parts)

            try container.encode(tempoMap,
                                 forKey: .tempoMap)

        case let .absoluteWall(parts):
            try container.encode(parts,
                                 forKey: .parts)

        case let .keyboardBeat(parts, tempoMap):
            try container.encode(parts,
                                 forKey: .parts)

            try container.encode(tempoMap,
                                 forKey: .tempoMap)

        case let .keyboardWall(parts):
            try container.encode(parts,
                                 forKey: .parts)

        case let .standardBeat(parts, tempoMap):
            try container.encode(parts,
                                 forKey: .parts)

            try container.encode(tempoMap,
                                 forKey: .tempoMap)

        case let .standardWall(parts):
            try container.encode(parts,
                                 forKey: .parts)
        }
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case parts
        case pitchNotation
        case tempoMap
        case timeBasis
    }
}

// MARK: - Sendable

extension Work.Content: Sendable {
}
