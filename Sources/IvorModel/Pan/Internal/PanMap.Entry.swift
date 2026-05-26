// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

extension PanMap {

    // MARK: Internal Nested Types

    internal enum Entry {
        case extended(TimeType, Pan, Extras)
        case simple(TimeType, Pan)
    }
}

// MARK: -

extension PanMap.Entry {

    // MARK: Internal Initializers

    internal init(time: TimeType,
                  pan: Pan,
                  extras: Extras?) {
        if let extras, !extras.isEmpty {
            self = .extended(time, pan, extras)
        } else {
            self = .simple(time, pan)
        }
    }

    // MARK: Internal Instance Properties

    internal var extras: Extras? {
        switch self {
        case let .extended(_, _, extras):
            extras

        default:
            nil
        }
    }

    internal var pan: Pan {
        switch self {
        case let .extended(_, pan, _),
            let .simple(_, pan):
            pan
        }
    }

    internal var time: TimeType {
        switch self {
        case let .extended(time, _, _),
            let .simple(time, _):
            time
        }
    }
}

// MARK: - Codable

extension PanMap.Entry: Codable {

    // MARK: Internal Initializers

    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let time = try container.decode(TimeType.self)
        let pan = try container.decode(Pan.self)
        let extras = try container.decodeIfPresent(Extras.self)

        self.init(time: time,
                  pan: pan,
                  extras: extras)
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(time)
        try container.encode(pan)

        if let extras {
            try container.encode(extras)
        }
    }
}

// MARK: - Comparable

extension PanMap.Entry: Comparable {

    // MARK: Internal Type Methods

    internal static func < (lhs: Self,
                            rhs: Self) -> Bool {
        lhs.time < rhs.time
    }
}

// MARK: - Sendable

extension PanMap.Entry: Sendable {
}
