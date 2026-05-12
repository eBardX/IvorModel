internal import XestiTools

extension PositionMap {

    // MARK: Internal Nested Types

    internal enum Entry {
        case custom(TimeType, Position, Extras)
        case simple(TimeType, Position)
    }
}

// MARK: -

extension PositionMap.Entry {

    // MARK: Internal Initializers

    internal init(time: TimeType,
                  position: Position,
                  extras: Extras?) {
        if let extras, !extras.isEmpty {
            self = .custom(time, position, extras)
        } else {
            self = .simple(time, position)
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

    internal var position: Position {
        switch self {
        case let .custom(_, position, _),
            let .simple(_, position):
            position
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

extension PositionMap.Entry: Codable {

    // MARK: Internal Initializers

    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let time = try container.decode(TimeType.self)
        let position = try container.decode(Position.self)
        let extras = try container.decodeIfPresent(Extras.self)

        self.init(time: time,
                  position: position,
                  extras: extras)
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(time)
        try container.encode(position)

        if let extras {
            try container.encode(extras)
        }
    }
}

// MARK: - Comparable

extension PositionMap.Entry: Comparable {

    // MARK: Internal Type Methods

    internal static func < (lhs: Self,
                            rhs: Self) -> Bool {
        lhs.time < rhs.time
    }
}

// MARK: - Sendable

extension PositionMap.Entry: Sendable {
}
