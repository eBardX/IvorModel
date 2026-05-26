// © 2025–2026 John Gary Pusey (see LICENSE.md)

extension NoteEvent {

    // MARK: Public Nested Types

    /// A pitch annotated with its tie relationship to adjacent notes.
    public enum TiedPitch {
        /// A pitch that is not tied to any adjacent note.
        case neither(PitchType)

        /// A pitch that begins a tie to the following note.
        case start(PitchType)

        /// A pitch that ends a tie from the preceding note.
        case stop(PitchType)

        /// A pitch that ends a tie from the preceding note and begins a tie to the following note.
        case stopStart(PitchType)
    }
}

// MARK: -

extension NoteEvent.TiedPitch {

    // MARK: Public Initializers

    /// Creates a tied pitch from a pitch and tie flags.
    ///
    /// - Parameter pitch:      The pitch.
    /// - Parameter beginsTie:  A Boolean value indicating whether this pitch begins a tie to the following note. Defaults to `false`.
    /// - Parameter endsTie:    A Boolean value indicating whether this pitch ends a tie from the preceding note. Defaults to `false`.
    public init(pitch: PitchType,
                beginsTie: Bool = false,
                endsTie: Bool = false) {
        switch (beginsTie, endsTie) {
        case (false, false):
            self = .neither(pitch)

        case (false, true):
            self = .stop(pitch)

        case (true, false):
            self = .start(pitch)

        case (true, true):
            self = .stopStart(pitch)
        }
    }

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether this pitch begins a tie to the following note.
    public var beginsTie: Bool {
        switch self {
        case .start,
             .stopStart:
            true

        default:
            false
        }
    }

    /// A Boolean value indicating whether this pitch ends a tie from the preceding note.
    public var endsTie: Bool {
        switch self {
        case .stop,
             .stopStart:
            true

        default:
            false
        }
    }

    /// The pitch, regardless of tie state.
    public var pitch: PitchType {
        switch self {
        case let .neither(pit),
            let .start(pit),
            let .stop(pit),
            let .stopStart(pit):
            pit
        }
    }

    // MARK: Internal Instance Properties

    internal var tieCompareValue: Int {
        switch self {
        case .neither:
            0

        case .start:
            1

        case .stop:
            2

        case .stopStart:
            3
        }
    }
}

// MARK: - Codable

extension NoteEvent.TiedPitch: Codable {

    // MARK: Public Initializers

    /// Creates a tied pitch by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError.dataCorruptedError` if the encoded tag value is unrecognized.
    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let pitch = try container.decode(PitchType.self)
        let tag = try container.decode(String.self)

        switch tag {
        case "neither":
            self = .neither(pitch)

        case "start":
            self = .start(pitch)

        case "stop":
            self = .stop(pitch)

        case "stopStart":
            self = .stopStart(pitch)

        default:
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Invalid tag value")
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this tied pitch into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(pitch)

        switch self {
        case .neither:
            try container.encode("neither")

        case .start:
            try container.encode("start")

        case .stop:
            try container.encode("stop")

        case .stopStart:
            try container.encode("stopStart")
        }
    }
}

// MARK: - Comparable

extension NoteEvent.TiedPitch: Comparable {
    /// Returns a Boolean value indicating whether the left tied pitch compares less than the right.
    ///
    /// - Parameter lhs:    The left-hand tied pitch.
    /// - Parameter rhs:    The right-hand tied pitch.
    ///
    /// - Returns:  `true` if `lhs` precedes `rhs` when ordered by pitch then tie state.
    public static func < (lhs: Self,
                          rhs: Self) -> Bool {
        (lhs.pitch, rhs.tieCompareValue) < (rhs.pitch, lhs.tieCompareValue)
    }
}

// MARK: - Hashable

extension NoteEvent.TiedPitch: Hashable {
}

// MARK: - Sendable

extension NoteEvent.TiedPitch: Sendable {
}
