// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

private import IvorTiming

extension NoteTable {

    // MARK: Internal Nested Types

    internal enum Note {
        case extended(TimeType, DurationType, PitchType, PitchType, Extras)
        case glide(TimeType, DurationType, PitchType, PitchType)
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
            self = .extended(attack, duration, startPitch, endPitch, extras)
        } else if startPitch != endPitch {
            self = .glide(attack, duration, startPitch, endPitch)
        } else {
            self = .simple(attack, duration, startPitch)
        }
    }

    // MARK: Internal Instance Properties

    internal var attack: TimeType {
        switch self {
        case let .extended(attack, _, _, _, _),
            let .glide(attack, _, _, _),
            let .simple(attack, _, _):
            attack
        }
    }

    internal var duration: NoteTable.DurationType {
        switch self {
        case let .extended(_, duration, _, _, _),
            let .glide(_, duration, _, _),
            let .simple(_, duration, _):
            duration
        }
    }

    internal var endPitch: PitchType {
        switch self {
        case let .extended(_, _, _, endPitch, _),
            let .glide(_, _, _, endPitch):
            endPitch

        case let .simple(_, _, pitch):
            pitch
        }
    }

    internal var extras: Extras? {
        switch self {
        case let .extended(_, _, _, _, extras):
            extras

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

    internal var release: TimeType {
        switch self {
        case let .extended(attack, duration, _, _, _),
            let .glide(attack, duration, _, _),
            let .simple(attack, duration, _):
            attack.moved(by: DirectedDuration(duration: duration,
                                              direction: .forward)).require()
        }
    }

    internal var startPitch: PitchType {
        switch self {
        case let .extended(_, _, startPitch, _, _),
            let .glide(_, _, startPitch, _):
            startPitch

        case let .simple(_, _, pitch):
            pitch
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
            self = .extended(attack, duration, startPitch, endPitch ?? startPitch, extras)
        } else if let endPitch {
            self = .glide(attack, duration, startPitch, endPitch)
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
