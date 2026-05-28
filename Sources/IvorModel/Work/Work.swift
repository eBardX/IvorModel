// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

private import Foundation

/// A musical work containing parts and associated data.
public struct Work {

    // MARK: Public Type Properties

    /// The current work file format version.
    public static let currentVersion = 1

    // MARK: Public Initializers

    /// Creates a new work with the given name and content.
    ///
    /// - Parameter name:     The display name of the work. Defaults to an empty string.
    /// - Parameter content:  The ``Work/Content`` holding the parts. Defaults to an empty
    ///                       standard-beat content with an empty tempo map.
    public init(name: String = "",
                content: Content? = nil) {
        self.content = content ?? .standardBeat([],
                                                TempoMap())
        self.name = name
        self.workID = WorkID()
        self.version = Self.currentVersion
    }

    // MARK: Public Instance Properties

    /// The file format version of the work.
    public let version: Int

    /// The unique ID of the work.
    public let workID: WorkID

    /// The musical content of the work.
    public var content: Content

    /// The display name of the work.
    public var name: String
}

// MARK: -

extension Work {

    // MARK: Public Instance Properties

    /// The beat-time range spanned by all beat-time parts, or `nil` for wall-time content.
    public var beatTimeRange: ClosedRange<BeatTime>? {
        switch content {
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

    /// The number of parts in this work.
    public var partCount: Int {
        switch content {
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

    /// The pitch notation used by this work.
    public var pitchNotation: PitchNotation {
        content.pitchNotation
    }

    /// The tempo map associated with beat-time content, or `nil` for wall-time content.
    public var tempoMap: TempoMap? {
        switch content {
        case let .absoluteBeat(_, tmap),
            let .keyboardBeat(_, tmap),
            let .standardBeat(_, tmap):
            tmap

        default:
            nil
        }
    }

    /// The time basis used by this work.
    public var timeBasis: TimeBasis {
        content.timeBasis
    }

    /// The wall-time range spanned by all wall-time parts, or `nil` for beat-time content.
    public var wallTimeRange: ClosedRange<WallTime>? {
        switch content {
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

    // MARK: Public Instance Methods

    /// Returns the name of the part at the given index.
    ///
    /// - Parameter index:  The zero-based index of the part.
    ///
    /// - Returns:  The name of the part at `index`.
    public func partName(at index: Int) -> String {
        switch content {
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
}

// MARK: - Codable

extension Work: Codable {

    // MARK: Public Initializers

    /// Creates a work by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted;
    ///             otherwise, ``Work/Error/unsupportedVersion(_:)`` if the version is not supported.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.content = try container.decode(Content.self,
                                            forKey: .content)

        self.name = try container.decode(String.self,
                                         forKey: .name)

        self.version = try container.decode(Int.self,
                                            forKey: .version)

        guard version == Self.currentVersion
        else { throw Error.unsupportedVersion(version) }

        self.workID = try container.decode(WorkID.self,
                                           forKey: .workID)
    }

    // MARK: Public Instance Methods

    /// Encodes this work into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(workID,
                             forKey: .workID)

        try container.encode(version,
                             forKey: .version)

        try container.encode(name,
                             forKey: .name)

        try container.encode(content,
                             forKey: .content)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case content
        case name
        case version
        case workID
    }
}

// MARK: - Comparable

extension Work: Comparable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the left work compares less than the right.
    ///
    /// - Parameter lhs:    The left-hand work.
    /// - Parameter rhs:    The right-hand work.
    ///
    /// - Returns:  `true` if `lhs` precedes `rhs` when ordered by name then work ID.
    public static func < (lhs: Self,
                          rhs: Self) -> Bool {
        (lhs.name, lhs.workID) < (rhs.name, rhs.workID)
    }
}

// MARK: - Equatable

extension Work: Equatable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether two works are equal.
    ///
    /// - Parameter lhs:    The left-hand work.
    /// - Parameter rhs:    The right-hand work.
    ///
    /// - Returns:  `true` if both works have the same name and work ID.
    public static func == (lhs: Self,
                           rhs: Self) -> Bool {
        (lhs.name, lhs.workID) == (rhs.name, rhs.workID)
    }
}

// MARK: - Sendable

extension Work: Sendable {
}
