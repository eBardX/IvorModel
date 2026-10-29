// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension Template {

    // MARK: Public Nested Types

    /// The concrete pitches and durations a template’s source contained, after any tolerances.
    ///
    /// Generation starts from ``first``, and keeps relative states within ``pitchRange``. The app
    /// offers pitches and durations from here, since states may be relative. The members are what
    /// tolerances grouped together, which generation can draw from instead of the representative
    /// (see ``GenerationOptions/samplesMembers``).
    public struct Vocabulary<TimeType: TimeProtocol, PitchType: TemplatePitch> where TimeType.DurationType: TemplateDuration {

        // MARK: Public Initializers

        /// Creates a new vocabulary.
        ///
        /// - Parameter durations:          Each duration, with how many events had it.
        /// - Parameter pitches:            Each pitch, with how many times it sounded.
        /// - Parameter first:              The source’s first event, if any.
        /// - Parameter durationMembers:    For each representative duration, the durations a
        ///                                 tolerance grouped into it, with their counts.
        /// - Parameter pitchMembers:       For each representative pitch, the pitches a tolerance
        ///                                 grouped into it, with their counts.
        public init(durations: [TimeType.DurationType: Int] = [:],
                    pitches: [PitchType: Int] = [:],
                    first: NoteEvent<TimeType, PitchType>? = nil,
                    durationMembers: [TimeType.DurationType: [TimeType.DurationType: Int]] = [:],
                    pitchMembers: [PitchType: [PitchType: Int]] = [:]) {
            self.durationMembers = durationMembers
            self.durations = durations
            self.first = first
            self.pitchMembers = pitchMembers
            self.pitches = pitches
        }

        // MARK: Public Instance Properties

        /// For each representative duration, the durations a tolerance grouped into it, with how
        /// many events had each. Empty when no duration tolerance was used.
        public let durationMembers: [TimeType.DurationType: [TimeType.DurationType: Int]]

        /// Each duration in the source, with how many events had it.
        public let durations: [TimeType.DurationType: Int]

        /// The source’s first event, or `nil` if it had none.
        public let first: NoteEvent<TimeType, PitchType>?

        /// For each representative pitch, the pitches a tolerance grouped into it, with how many
        /// times each sounded. Empty when no pitch tolerance was used.
        public let pitchMembers: [PitchType: [PitchType: Int]]

        /// Each pitch in the source, with how many times it sounded.
        public let pitches: [PitchType: Int]
    }
}

// MARK: -

extension Template.Vocabulary {

    // MARK: Public Instance Properties

    /// The range of the source’s pitches, or `nil` if it had none.
    public var pitchRange: ClosedRange<PitchType>? {
        guard let lowest = pitches.keys.min(),
              let highest = pitches.keys.max()
        else { return nil }

        return lowest...highest
    }

    // MARK: Internal Instance Properties

    //
    // The most common duration, the shortest on a tie — for events whose states record none.
    //
    internal var commonestDuration: TimeType.DurationType? {
        Self._commonest(in: durations)
    }

    //
    // The most common pitch, the lowest on a tie — for sounding events whose states record none.
    //
    internal var commonestPitch: PitchType? {
        Self._commonest(in: pitches)
    }

    // MARK: Private Type Methods

    private static func _commonest<Value: Comparable>(in counts: [Value: Int]) -> Value? {
        counts.min { ($1.value, $0.key) < ($0.value, $1.key) }?.key
    }
}

// MARK: - Codable

extension Template.Vocabulary: Codable {

    // MARK: Public Initializers

    /// Creates a vocabulary by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.durationMembers = try Self._members(container.decode([_Members<TimeType.DurationType>].self,
                                                                  forKey: .durationMembers))

        self.durations = try Self._counts(container.decode([_Count<TimeType.DurationType>].self,
                                                           forKey: .durations))

        self.first = try container.decodeIfPresent(NoteEvent<TimeType, PitchType>.self,
                                                   forKey: .first)

        self.pitchMembers = try Self._members(container.decode([_Members<PitchType>].self,
                                                               forKey: .pitchMembers))

        self.pitches = try Self._counts(container.decode([_Count<PitchType>].self,
                                                         forKey: .pitches))
    }

    // MARK: Public Instance Methods

    /// Encodes this vocabulary into the provided encoder, each table sorted, so that the same
    /// vocabulary always encodes the same way.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encodeIfPresent(first,
                                      forKey: .first)

        try container.encode(Self._entries(durations),
                             forKey: .durations)

        try container.encode(Self._entries(pitches),
                             forKey: .pitches)

        try container.encode(Self._entries(durationMembers),
                             forKey: .durationMembers)

        try container.encode(Self._entries(pitchMembers),
                             forKey: .pitchMembers)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case durationMembers
        case durations
        case first
        case pitchMembers
        case pitches
    }

    private struct _Count<Value: Codable & Comparable & Hashable>: Codable {
        let value: Value
        let count: Int
    }

    private struct _Members<Value: Codable & Comparable & Hashable>: Codable {
        let value: Value
        let members: [_Count<Value>]
    }

    // MARK: Private Type Methods

    private static func _counts<Value>(_ entries: [_Count<Value>]) -> [Value: Int] {
        Dictionary(entries.map { ($0.value, $0.count) },
                   uniquingKeysWith: +)
    }

    private static func _entries<Value>(_ counts: [Value: Int]) -> [_Count<Value>] {
        counts.keys.sorted().map { _Count(value: $0, count: counts[$0, default: 0]) }
    }

    private static func _entries<Value>(_ members: [Value: [Value: Int]]) -> [_Members<Value>] {
        members.keys.sorted().map { _Members(value: $0, members: _entries(members[$0, default: [:]])) }
    }

    private static func _members<Value>(_ entries: [_Members<Value>]) -> [Value: [Value: Int]] {
        Dictionary(entries.map { ($0.value, _counts($0.members)) }) { lhs, _ in lhs }
    }
}

// MARK: - Hashable

extension Template.Vocabulary: Hashable {
}

// MARK: - Sendable

extension Template.Vocabulary: Sendable {
}
