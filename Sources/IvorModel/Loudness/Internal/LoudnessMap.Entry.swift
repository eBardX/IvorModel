internal import XestiTools

extension LoudnessMap {

    // MARK: Internal Nested Types

    internal enum Entry {
        case custom(TimeType, Loudness, Extras)
        case simple(TimeType, Loudness)
    }
}

// MARK: -

extension LoudnessMap.Entry {

    // MARK: Internal Initializers

    internal init(time: TimeType,
                  loudness: Loudness,
                  extras: Extras?) {
        if let extras, !extras.isEmpty {
            self = .custom(time, loudness, extras)
        } else {
            self = .simple(time, loudness)
        }
    }

    // MARK: Internal Instance Properties

    internal var extras: Extras? {
        switch self {
        case let .custom(_, _, extras):
            extras

        default:
            nil
        }
    }

    internal var loudness: Loudness {
        switch self {
        case let .custom(_, loudness, _),
            let .simple(_, loudness):
            loudness
        }
    }

    internal var time: TimeType {
        switch self {
        case let .custom(time, _, _),
            let .simple(time, _):
            time
        }
    }
}

// MARK: - Codable

extension LoudnessMap.Entry: Codable {

    // MARK: Internal Initializers

    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let time = try container.decode(TimeType.self)
        let loudness = try container.decode(Loudness.self)
        let extras = try container.decodeIfPresent(Extras.self)

        self.init(time: time,
                  loudness: loudness,
                  extras: extras)
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(time)
        try container.encode(loudness)

        if let extras {
            try container.encode(extras)
        }
    }
}

// MARK: - Comparable

extension LoudnessMap.Entry: Comparable {

    // MARK: Internal Type Methods

    internal static func < (lhs: Self,
                            rhs: Self) -> Bool {
        lhs.time < rhs.time
    }
}

// MARK: - Sendable

extension LoudnessMap.Entry: Sendable {
}
