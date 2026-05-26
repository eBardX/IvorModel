// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Work {
    /// The musical content of a work, parameterized by pitch notation and time basis.
    public enum Content {
        /// Beat-time parts using absolute (frequency) pitch notation, with an associated tempo map.
        case absoluteBeat([Part<BeatTime, Frequency>], TempoMap)

        /// Wall-time parts using absolute (frequency) pitch notation.
        case absoluteWall([Part<WallTime, Frequency>])

        /// Beat-time parts using keyboard (MIDI note number) pitch notation, with an associated tempo map.
        case keyboardBeat([Part<BeatTime, NoteNumber>], TempoMap)

        /// Wall-time parts using keyboard (MIDI note number) pitch notation.
        case keyboardWall([Part<WallTime, NoteNumber>])

        /// Beat-time parts using standard (staff) pitch notation, with an associated tempo map.
        case standardBeat([Part<BeatTime, Pitch>], TempoMap)

        /// Wall-time parts using standard (staff) pitch notation.
        case standardWall([Part<WallTime, Pitch>])
    }
}

// MARK: -

extension Work.Content {

    // MARK: Public Instance Properties

    /// The beat-time range spanned by all beat-time parts, or `nil` for wall-time content.
    public var beatTimeRange: ClosedRange<BeatTime>? {
        switch self {
        case let .absoluteBeat(parts, _):
            Self._timeRange(of: parts)

        case let .keyboardBeat(parts, _):
            Self._timeRange(of: parts)

        case let .standardBeat(parts, _):
            Self._timeRange(of: parts)

        default:
            nil
        }
    }

    /// The number of parts in this content.
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

    /// The tempo map associated with beat-time content, or `nil` for wall-time content.
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

    /// The wall-time range spanned by all wall-time parts, or `nil` for beat-time content.
    public var wallTimeRange: ClosedRange<WallTime>? {
        switch self {
        case let .absoluteWall(parts):
            Self._timeRange(of: parts)

        case let .keyboardWall(parts):
            Self._timeRange(of: parts)

        case let .standardWall(parts):
            Self._timeRange(of: parts)

        default:
            nil
        }
    }

    // MARK: Public Instance Methods

    /// Returns the name of the part at the given index.
    ///
    /// - Parameter index:  The zero-based index of the part.
    ///
    /// - Returns:  The name of the part at `index`.
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

    private static func _timeRange<TimeType: TimeProtocol>(of parts: [Part<TimeType, some PitchProtocol>]) -> ClosedRange<TimeType>? {
        parts.reduce(nil) { acc, part in
            guard let partRange = part.timeRange
            else { return acc }

            guard let acc
            else { return partRange }

            return min(acc.lowerBound, partRange.lowerBound)...max(acc.upperBound, partRange.upperBound)
        }
    }
}

// MARK: - Codable

extension Work.Content: Codable {

    // MARK: Public Initializers

    /// Creates a work content value by decoding from the provided decoder.
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

    /// Encodes this work content into the provided encoder.
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
