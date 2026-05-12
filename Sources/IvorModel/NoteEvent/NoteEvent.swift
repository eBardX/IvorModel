public import IvorTiming
public import IvorTuning

public struct NoteEvent<TimeType: TimeProtocol, PitchType: PitchProtocol> {

    // MARK: Public Nested Types

    public typealias DurationType = TimeType.DurationType

    // MARK: Public Initializers

    public init(pitches: [PitchType],
                duration: DurationType) {
        self.init(tiedPitches: pitches.map { TiedPitch(pitch: $0) },
                  duration: duration)
    }

    public init(tiedPitches: [TiedPitch] = [],
                duration: DurationType) {
        self.duration = duration
        self.tiedPitches = Self._standardize(tiedPitches)
    }

    // MARK: Public Instance Properties

    public let duration: DurationType
    public let tiedPitches: [TiedPitch]

    // MARK: Private Type Methods

    private static func _standardize(_ tiedPitches: [TiedPitch]) -> [TiedPitch] {
        tiedPitches.sorted()
    }
}

// MARK: - Codable

extension NoteEvent: Codable {

    // MARK: Public Initializers

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.duration = try container.decode(DurationType.self,
                                             forKey: .duration)

        self.tiedPitches = try container.decode([TiedPitch].self,
                                                forKey: .tiedPitches)
    }

    // MARK: Public Instance Methods

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(tiedPitches,
                             forKey: .tiedPitches)

        try container.encode(duration,
                             forKey: .duration)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case duration
        case tiedPitches
    }
}

// MARK: - Comparable

extension NoteEvent: Comparable {
    public static func < (lhs: Self,
                          rhs: Self) -> Bool {
        if lhs.tiedPitches == rhs.tiedPitches {
            lhs.duration < rhs.duration
        } else {
            lhs.tiedPitches.lexicographicallyPrecedes(rhs.tiedPitches)
        }
    }
}

// MARK: - Hashable

extension NoteEvent: Hashable {
}

// MARK: - Sendable

extension NoteEvent: Sendable {
}
