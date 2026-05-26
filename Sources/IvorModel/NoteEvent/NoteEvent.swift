// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

/// A musical note event consisting of a set of tied pitches and a duration.
public struct NoteEvent<TimeType: TimeProtocol, PitchType: PitchProtocol> {

    // MARK: Public Nested Types

    /// The duration type associated with the time type.
    public typealias DurationType = TimeType.DurationType

    // MARK: Public Initializers

    /// Creates a note event from an array of pitches and a duration.
    ///
    /// - Parameter pitches:    The pitches sounding during this event; none are tied.
    /// - Parameter duration:   The duration of the event.
    public init(pitches: [PitchType],
                duration: DurationType) {
        self.init(tiedPitches: pitches.map { TiedPitch(pitch: $0) },
                  duration: duration)
    }

    /// Creates a note event from an array of tied pitches and a duration.
    ///
    /// - Parameter tiedPitches:    The tie-annotated pitches sounding during this event. Defaults to empty.
    /// - Parameter duration:       The duration of the event.
    public init(tiedPitches: [TiedPitch] = [],
                duration: DurationType) {
        self.duration = duration
        self.tiedPitches = Self._standardize(tiedPitches)
    }

    // MARK: Public Instance Properties

    /// The duration of this note event.
    public let duration: DurationType

    /// The tie-annotated pitches sounding during this note event.
    public let tiedPitches: [TiedPitch]

    // MARK: Private Type Methods

    private static func _standardize(_ tiedPitches: [TiedPitch]) -> [TiedPitch] {
        tiedPitches.sorted()
    }
}

// MARK: - Codable

extension NoteEvent: Codable {

    // MARK: Public Initializers

    /// Creates a note event by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.duration = try container.decode(DurationType.self,
                                             forKey: .duration)

        self.tiedPitches = try container.decode([TiedPitch].self,
                                                forKey: .tiedPitches)
    }

    // MARK: Public Instance Methods

    /// Encodes this note event into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
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
    /// Returns a Boolean value indicating whether the left note event compares less than the right.
    ///
    /// - Parameter lhs:    The left-hand note event.
    /// - Parameter rhs:    The right-hand note event.
    ///
    /// - Returns:  `true` if `lhs` precedes `rhs` when ordered by tied pitches then duration.
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
