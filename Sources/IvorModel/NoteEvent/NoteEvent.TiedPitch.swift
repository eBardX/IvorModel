extension NoteEvent {

    // MARK: Public Nested Types

    public enum TiedPitch {
        case neither(PitchType)
        case start(PitchType)
        case stop(PitchType)
        case stopStart(PitchType)
    }
}

// MARK: -

extension NoteEvent.TiedPitch {

    // MARK: Public Initializers

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

    public var beginsTie: Bool {
        switch self {
        case .start,
             .stopStart:
            true

        default:
            false
        }
    }

    public var endsTie: Bool {
        switch self {
        case .stop,
             .stopStart:
            true

        default:
            false
        }
    }

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

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let pitch = try container.decode(PitchType.self)
        let tag = try container.decode(String.self)

        switch tag {
        case "neither":
            self = .neither(pitch)

        case "start":
            self = .neither(pitch)

        case "stop":
            self = .neither(pitch)

        case "stopStart":
            self = .neither(pitch)

        default:
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Invalid tag value")
        }
    }

    // MARK: Public Instance Methods

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
