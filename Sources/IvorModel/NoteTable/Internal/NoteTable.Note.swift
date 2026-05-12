internal import XestiTools

private import IvorTiming

extension NoteTable {

    // MARK: Internal Nested Types

    internal enum Note {
        case custom(TimeType, DurationType, PitchType, PitchType, Extras)
        case portamento(TimeType, DurationType, PitchType, PitchType)          // need better name
        case simple(TimeType, DurationType, PitchType)
    }
}

// MARK: -

extension NoteTable.Note {

    // MARK: Internal Initializers

    internal init(attack: TimeType,
                  duration: NoteTable.DurationType,
                  startPitch: PitchType,
                  endPitch: PitchType,
                  extras: Extras?) {
        if let extras, !extras.isEmpty {
            self = .custom(attack, duration, startPitch, endPitch, extras)
        } else if startPitch != endPitch {
            self = .portamento(attack, duration, startPitch, endPitch)
        } else {
            self = .simple(attack, duration, startPitch)
        }
    }

    // MARK: Internal Instance Properties

    internal var attack: TimeType {
        switch self {
        case let .custom(att, _, _, _, _),
            let .portamento(att, _, _, _),
            let .simple(att, _, _):
            att
        }
    }

    internal var duration: NoteTable.DurationType {
        switch self {
        case let .custom(_, dur, _, _, _),
            let .portamento(_, dur, _, _),
            let .simple(_, dur, _):
            dur
        }
    }

    internal var extras: Extras? {
        switch self {
        case let .custom(_, _, _, _, ext):
            ext

        default:
            nil
        }
    }

    internal var maximumPitch: PitchType {
        max(startPitch, endPitch)
    }

    internal var minimumPitch: PitchType {
        min(startPitch, endPitch)
    }

    internal var endPitch: PitchType {
        switch self {
        case let .custom(_, _, _, epit, _),
            let .portamento(_, _, _, epit):
            epit

        case let .simple(_, _, pit):
            pit
        }
    }

    internal var release: TimeType {
        switch self {
        case let .custom(att, dur, _, _, _),
            let .portamento(att, dur, _, _),
            let .simple(att, dur, _):
            att.moved(by: dur,
                      direction: .forward).require()
        }
    }

    internal var startPitch: PitchType {
        switch self {
        case let .custom(_, _, spit, _, _),
            let .portamento(_, _, spit, _):
            spit

        case let .simple(_, _, pit):
            pit
        }
    }
}

// MARK: - Codable

extension NoteTable.Note: Codable {

    // MARK: Internal Initializers

    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let attack = try container.decode(TimeType.self)
        let duration = try container.decode(NoteTable.DurationType.self)
        let startPitch = try container.decode(PitchType.self)
        let endPitch = try container.decodeIfPresent(PitchType.self)
        let extras = try container.decodeIfPresent(Extras.self)

        if let extras {
            self = .custom(attack, duration, startPitch, endPitch ?? startPitch, extras)
        } else if let endPitch {
            self = .portamento(attack, duration, startPitch, endPitch)
        } else {
            self = .simple(attack, duration, startPitch)
        }
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(attack)
        try container.encode(duration)
        try container.encode(startPitch)

        if endPitch != startPitch {
            try container.encode(endPitch)
        }

        if let extras {
            try container.encode(extras)
        }
    }
}

// MARK: - Comparable

extension NoteTable.Note: Comparable {

    // MARK: Internal Type Methods

    internal static func < (lhs: Self,
                            rhs: Self) -> Bool {
        (lhs.attack, lhs.duration, rhs.startPitch, rhs.endPitch) < (rhs.attack, rhs.duration, lhs.startPitch, lhs.endPitch)
    }
}

// MARK: - Sendable

extension NoteTable.Note: Sendable {
}
