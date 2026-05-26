// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

extension DynamicMap {

    // MARK: Internal Nested Types

    internal enum Entry {
        case extended(TimeType, Dynamic, Extras)
        case simple(TimeType, Dynamic)
    }
}

// MARK: -

extension DynamicMap.Entry {

    // MARK: Internal Initializers

    internal init(time: TimeType,
                  dynamic: Dynamic,
                  extras: Extras?) {
        if let extras, !extras.isEmpty {
            self = .extended(time, dynamic, extras)
        } else {
            self = .simple(time, dynamic)
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

    internal var dynamic: Dynamic {
        switch self {
        case let .extended(_, dynamic, _),
            let .simple(_, dynamic):
            dynamic
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

extension DynamicMap.Entry: Codable {

    // MARK: Internal Initializers

    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let time = try container.decode(TimeType.self)
        let dynamic = try container.decode(Dynamic.self)
        let extras = try container.decodeIfPresent(Extras.self)

        self.init(time: time,
                  dynamic: dynamic,
                  extras: extras)
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(time)
        try container.encode(dynamic)

        if let extras {
            try container.encode(extras)
        }
    }
}

// MARK: - Comparable

extension DynamicMap.Entry: Comparable {

    // MARK: Internal Type Methods

    internal static func < (lhs: Self,
                            rhs: Self) -> Bool {
        lhs.time < rhs.time
    }
}

// MARK: - Sendable

extension DynamicMap.Entry: Sendable {
}
