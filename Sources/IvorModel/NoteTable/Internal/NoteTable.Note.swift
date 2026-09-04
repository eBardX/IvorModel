// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

private import IvorTiming

extension NoteTable {

    // MARK: Internal Nested Types

    //
    // The two pitches are folded into one tuple slot, not two separate associated
    // values, to keep `extended` under `enum_case_associated_values_count`'s
    // threshold now that identity is a sixth field every case carries.
    //
    internal enum Note {
        case extended(NoteID, TimeType, DurationType, (start: PitchType, end: PitchType), Extras)
        case glide(NoteID, TimeType, DurationType, (start: PitchType, end: PitchType))
        case simple(NoteID, TimeType, DurationType, PitchType)
    }
}

// MARK: -

extension NoteTable.Note {

    // MARK: Internal Initializers

    //
    // `noteID` defaults to a fresh identity — the common case, a newly inserted or
    // decoded note. Passing one explicitly is for the `move*` methods, which need
    // to keep an existing identity across a content change.
    //
    internal init(noteID: NoteTable.NoteID = NoteTable.NoteID(),
                  attack: TimeType,
                  duration: NoteTable.DurationType,
                  startPitch: PitchType,
                  endPitch: PitchType,
                  extras: Extras?) {
        if let extras, !extras.isEmpty {
            self = .extended(noteID, attack, duration, (startPitch, endPitch), extras)
        } else if startPitch != endPitch {
            self = .glide(noteID, attack, duration, (startPitch, endPitch))
        } else {
            self = .simple(noteID, attack, duration, startPitch)
        }
    }

    // MARK: Internal Instance Properties

    internal var attack: TimeType {
        switch self {
        case let .extended(_, attack, _, _, _),
            let .glide(_, attack, _, _),
            let .simple(_, attack, _, _):
            attack
        }
    }

    internal var duration: NoteTable.DurationType {
        switch self {
        case let .extended(_, _, duration, _, _),
            let .glide(_, _, duration, _),
            let .simple(_, _, duration, _):
            duration
        }
    }

    internal var endPitch: PitchType {
        switch self {
        case let .extended(_, _, _, pitches, _):
            pitches.end

        case let .glide(_, _, _, pitches):
            pitches.end

        case let .simple(_, _, _, pitch):
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

    internal var noteID: NoteTable.NoteID {
        switch self {
        case let .extended(noteID, _, _, _, _),
            let .glide(noteID, _, _, _),
            let .simple(noteID, _, _, _):
            noteID
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
        case let .extended(_, attack, duration, _, _),
            let .glide(_, attack, duration, _),
            let .simple(_, attack, duration, _):
            attack.moved(by: DirectedDuration(duration: duration,
                                              direction: .forward)).require()
        }
    }

    internal var startPitch: PitchType {
        switch self {
        case let .extended(_, _, _, pitches, _):
            pitches.start

        case let .glide(_, _, _, pitches):
            pitches.start

        case let .simple(_, _, _, pitch):
            pitch
        }
    }
}

// MARK: - Codable

extension NoteTable.Note: Codable {

    // MARK: Internal Initializers

    //
    // Identity is never encoded (see `NoteID`'s doc comment), so decoding always
    // assigns a fresh one via the default parameter — indistinguishable from a
    // freshly inserted note.
    //
    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let attack = try container.decode(TimeType.self)
        let duration = try container.decode(NoteTable.DurationType.self)
        let startPitch = try container.decode(PitchType.self)
        let endPitch = try container.decodeIfPresent(PitchType.self)
        let extras = try container.decodeIfPresent(Extras.self)

        self.init(attack: attack,
                  duration: duration,
                  startPitch: startPitch,
                  endPitch: endPitch ?? startPitch,
                  extras: extras)
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(attack)
        try container.encode(duration)
        try container.encode(startPitch)

        if endPitch != startPitch || extras != nil {
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

// MARK: - Equatable

extension NoteTable.Note: Equatable {

    // MARK: Internal Type Methods

    //
    // Identity is deliberately excluded: two notes are equal here exactly when
    // they carry the same attack, duration, pitches, and extras, regardless of
    // which `NoteID` each holds. Unlike the time-keyed maps, this equality is not
    // used to reject or collapse anything on insert — a note table allows exact
    // duplicates — but it keeps the same "content, not identity" contract the other
    // map types establish, and is what lets tests construct content-identical notes
    // independently and expect them equal.
    //
    internal static func == (lhs: Self,
                             rhs: Self) -> Bool {
        (lhs.attack, lhs.duration, lhs.startPitch, lhs.endPitch, lhs.extras) ==
            (rhs.attack, rhs.duration, rhs.startPitch, rhs.endPitch, rhs.extras)
    }
}

// MARK: - Sendable

extension NoteTable.Note: Sendable {
}
