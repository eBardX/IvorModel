// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorSMPTE
public import IvorTiming
public import IvorTuning

private import Foundation
private import XestiTools

/// A musical work containing parts and associated data.
public struct Work {

    // MARK: Public Initializers

    /// Creates a new work with the given name, content, SMPTE start time, and metadata.
    ///
    /// - Parameter name:           The display name of the work. Its whitespace is normalized
    ///                             to a single line. Defaults to an empty string.
    /// - Parameter content:        The ``Work/Content`` holding the parts. Defaults to an empty
    ///                             standard-beat content with an empty tempo map.
    /// - Parameter smpteStartTime: The SMPTE timecode at which the work’s wall time zero falls.
    ///                             Defaults to ``defaultSMPTEStartTime``.
    /// - Parameter metadata:       The descriptive ``Work/Metadata`` of the work. Defaults to
    ///                             empty metadata.
    public init(name: String = "",
                content: Content? = nil,
                smpteStartTime: SMPTETime = Self.defaultSMPTEStartTime,
                metadata: Metadata = Metadata()) {
        self.unsafeContent = content ?? .standardBeat([],
                                                      TempoMap())
        self.isLocked = false
        self.metadata = metadata
        self.name = name.normalizingWhitespace()
        self.smpteStartTime = smpteStartTime
        self.workID = WorkID()
        self.version = Self.currentVersion
    }

    // MARK: Public Instance Properties

    /// The file format version of the work.
    public let version: Int

    /// The unique ID of the work.
    public let workID: WorkID

    /// A Boolean value indicating whether this work is locked.
    ///
    /// A locked work cannot be modified until it is unlocked. Every method that would change its
    /// ``content``, ``metadata``, ``name`` or ``smpteStartTime`` throws ``Work/Error/workIsLocked`` instead,
    /// and ``Project/removeWork(_:)`` refuses to remove it. Methods that return a new work, such
    /// as ``duplicated()`` or ``warped()``, leave this work untouched and so are always permitted.
    /// Setting `isLocked` itself is always permitted, so a locked work can always be unlocked.
    public var isLocked: Bool

    /// Descriptive metadata about this work.
    ///
    /// It is about the work, not part of its identity, so it plays no part in comparing works.
    /// To change it, use ``modifyMetadata(_:)``.
    public internal(set) var metadata: Metadata

    /// The display name of the work, with whitespace normalized to a single line.
    ///
    /// To change it, use ``rename(to:)``.
    public internal(set) var name: String

    /// The SMPTE timecode at which the work’s wall time zero falls.
    ///
    /// Its frame rate is the one the work’s times are shown and entered in when shown as timecode.
    /// It only has meaning for wall-time content, but is kept whatever the time basis, so it isn’t
    /// lost if the content is converted to beat time and back. To change it, use
    /// ``setSMPTEStartTime(_:)``.
    public internal(set) var smpteStartTime: SMPTETime

    /// The musical content of the work.
    ///
    /// To replace it, use ``replaceContent(with:)``.
    public internal(set) var content: Content {
        get { unsafeContent }
        set {
            //
            // Every public mutator checks `isLocked` (via `ensureUnlocked()`) before it gets here,
            // so reaching this with a locked work is a bug in this package.
            //
            precondition(!isLocked, "Cannot assign content to a locked work.")

            unsafeContent = newValue
        }
    }

    // MARK: Private Instance Properties

    //
    // Bypasses `content`'s locked-check setter — only for use by this type's own initializers and
    // `Codable` conformance, where decoding must always succeed regardless of the decoded
    // `isLocked` value.
    //
    private var unsafeContent: Content
}

// MARK: -

extension Work {

    // MARK: Public Type Properties

    /// The current work file format version.
    public static let currentVersion = 1

    /// The SMPTE start time a work has unless given another: 00:00:00:00 at 25 fps.
    public static let defaultSMPTEStartTime = SMPTETime(frameRate: .fps25,
                                                        frameCount: 0,
                                                        subframe: 0)!  // swiftlint:disable:this force_unwrapping

    // MARK: Public Instance Properties

    /// The beat-time range spanned by all beat-time parts, or `nil` for wall-time content.
    public var beatTimeRange: ClosedRange<BeatTime>? {
        switch content {
        case let .absoluteBeat(parts, _):
            Self.aggregateTimeRange(of: parts)

        case let .keyboardBeat(parts, _):
            Self.aggregateTimeRange(of: parts)

        case let .standardBeat(parts, _):
            Self.aggregateTimeRange(of: parts)

        default:
            nil
        }
    }

    /// The total number of notes across all parts in this work.
    public var noteCount: Int {
        switch content {
        case let .absoluteBeat(parts, _):
            parts.reduce(0) { $0 + $1.noteCount }

        case let .absoluteWall(parts):
            parts.reduce(0) { $0 + $1.noteCount }

        case let .keyboardBeat(parts, _):
            parts.reduce(0) { $0 + $1.noteCount }

        case let .keyboardWall(parts):
            parts.reduce(0) { $0 + $1.noteCount }

        case let .standardBeat(parts, _):
            parts.reduce(0) { $0 + $1.noteCount }

        case let .standardWall(parts):
            parts.reduce(0) { $0 + $1.noteCount }
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

    /// The pitch range spanned by all parts, or `nil` if the work contains no notes.
    ///
    /// Both bounds always share the same underlying pitch type — ``Frequency``,
    /// ``NoteNumber``, or ``Pitch`` — as determined by ``pitchNotation``.
    public var pitchRange: (lowerBound: any PitchProtocol, upperBound: any PitchProtocol)? {
        switch content {
        case let .absoluteBeat(parts, _):
            Self.aggregatePitchRange(of: parts).map { ($0.lowerBound, $0.upperBound) }

        case let .absoluteWall(parts):
            Self.aggregatePitchRange(of: parts).map { ($0.lowerBound, $0.upperBound) }

        case let .keyboardBeat(parts, _):
            Self.aggregatePitchRange(of: parts).map { ($0.lowerBound, $0.upperBound) }

        case let .keyboardWall(parts):
            Self.aggregatePitchRange(of: parts).map { ($0.lowerBound, $0.upperBound) }

        case let .standardBeat(parts, _):
            Self.aggregatePitchRange(of: parts).map { ($0.lowerBound, $0.upperBound) }

        case let .standardWall(parts):
            Self.aggregatePitchRange(of: parts).map { ($0.lowerBound, $0.upperBound) }
        }
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
            Self.aggregateTimeRange(of: parts)

        case let .keyboardWall(parts):
            Self.aggregateTimeRange(of: parts)

        case let .standardWall(parts):
            Self.aggregateTimeRange(of: parts)

        default:
            nil
        }
    }

    // MARK: Public Instance Methods

    /// Returns a copy of this work with the same content, ``smpteStartTime``, and ``metadata``
    /// but a distinct, freshly minted ``WorkID``.
    public func duplicated() -> Self {
        Self(name: name,
             content: content,
             smpteStartTime: smpteStartTime,
             metadata: metadata)
    }

    /// Edits the metadata of this work in place.
    ///
    /// - Parameter body:   A closure that edits the metadata it is passed.
    ///
    /// - Returns:  The value returned by `body`.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked.
    public mutating func modifyMetadata<R>(_ body: (inout Metadata) -> R) throws(Error) -> R {
        try ensureUnlocked()

        return body(&metadata)
    }

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

    /// Changes the display name of this work.
    ///
    /// - Parameter name:   The new display name. Its whitespace is normalized to a single line.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked.
    public mutating func rename(to name: String) throws(Error) {
        try ensureUnlocked()

        self.name = name.normalizingWhitespace()
    }

    /// Replaces the musical content of this work.
    ///
    /// - Parameter content:    The new ``Work/Content``.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked.
    public mutating func replaceContent(with content: Content) throws(Error) {
        try ensureUnlocked()

        self.content = content
    }

    /// Changes the SMPTE timecode at which this work’s wall time zero falls.
    ///
    /// - Parameter smpteStartTime: The new SMPTE start time.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked.
    public mutating func setSMPTEStartTime(_ smpteStartTime: SMPTETime) throws(Error) {
        try ensureUnlocked()

        self.smpteStartTime = smpteStartTime
    }

    // MARK: Internal Type Methods

    //
    // Visibility is internal (not private) so `Work+Transform.swift` can reuse it to compute a
    // shared anchor over a targeted subset of parts, rather than recomputing this reduction
    // independently.
    //
    internal static func aggregatePitchRange<PitchType: PitchProtocol>(of parts: [Part<some TimeProtocol, PitchType>]) -> ClosedRange<PitchType>? {
        parts.reduce(nil) { acc, part in
            guard let partRange = part.pitchRange
            else { return acc }

            guard let acc
            else { return partRange }

            return min(acc.lowerBound, partRange.lowerBound)...max(acc.upperBound, partRange.upperBound)
        }
    }

    //
    // Visibility is internal (not private) so `Work+Transform.swift` can reuse it to compute a
    // shared anchor over a targeted subset of parts, rather than recomputing this reduction
    // independently.
    //
    internal static func aggregateTimeRange<TimeType: TimeProtocol>(of parts: [Part<TimeType, some PitchProtocol>]) -> ClosedRange<TimeType>? {
        parts.reduce(nil) { acc, part in
            guard let partRange = part.timeRange
            else { return acc }

            guard let acc
            else { return partRange }

            return min(acc.lowerBound, partRange.lowerBound)...max(acc.upperBound, partRange.upperBound)
        }
    }

    // MARK: Internal Instance Methods

    //
    // Called first by every public mutator, so a locked work is rejected before anything else is
    // checked and is left unchanged.
    //
    internal func ensureUnlocked() throws(Error) {
        guard !isLocked
        else { throw Error.workIsLocked }
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

        //
        // Decoded directly into the backing storage, bypassing `content`'s locked-check setter —
        // decoding must always succeed, regardless of the decoded `isLocked` value.
        //
        self.unsafeContent = try container.decode(Content.self,
                                                  forKey: .content)

        self.isLocked = try container.decode(Bool.self,
                                             forKey: .isLocked)

        self.metadata = try container.decode(Metadata.self,
                                             forKey: .metadata)

        self.name = try container.decode(String.self,
                                         forKey: .name).normalizingWhitespace()

        self.smpteStartTime = try Self._decodeSMPTEStartTime(from: container)

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

        try container.encode(isLocked,
                             forKey: .isLocked)

        try container.encode(name,
                             forKey: .name)

        try container.encode([smpteStartTime.frameRate.description, smpteStartTime.description],
                             forKey: .smpteStartTime)

        try container.encode(metadata,
                             forKey: .metadata)

        try container.encode(content,
                             forKey: .content)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case content
        case isLocked
        case metadata
        case name
        case smpteStartTime
        case version
        case workID
    }

    // MARK: Private Type Methods

    //
    // Kept as a frame rate and timecode pair of strings, since `SMPTETime` isn't `Codable`.
    //
    private static func _decodeSMPTEStartTime(from container: KeyedDecodingContainer<CodingKeys>) throws -> SMPTETime {
        let strings = try container.decode([String].self,
                                           forKey: .smpteStartTime)

        guard strings.count == 2,
              let frameRate = SMPTEFrameRate(string: strings[0]),
              let startTime = SMPTETime(string: strings[1],
                                        frameRate: frameRate)
        else { throw DecodingError.dataCorruptedError(forKey: .smpteStartTime,
                                                      in: container,
                                                      debugDescription: "Invalid SMPTE start time: \(strings)") }

        return startTime
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
