// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

private import IvorTiming

extension NoteTable {

    // MARK: Internal Nested Types

    //
    // The two pitches are folded into one tuple slot, not two separate associated
    // values, to keep `extended` under `enum_case_associated_values_count`'s
    // threshold. Likewise the extras and ornamentation share one `Payload` slot, so
    // a note with neither stays `glide` or `simple` and encodes compactly.
    //
    internal enum StoredNote {
        case extended(NoteID, TimeType, DurationType, (start: PitchType, end: PitchType), Payload)
        case glide(NoteID, TimeType, DurationType, (start: PitchType, end: PitchType))
        case simple(NoteID, TimeType, DurationType, PitchType)
    }
}

// MARK: -

extension NoteTable.StoredNote {

    // MARK: Internal Initializers

    //
    // `noteID` defaults to a fresh identity — the common case, a newly inserted or
    // decoded note. Passing one explicitly is for the `move*` methods, which need
    // to keep an existing identity across a content change.
    //
    internal init(noteID: NoteID = NoteID(),
                  attack: TimeType,
                  duration: NoteTable.DurationType,
                  startPitch: PitchType,
                  endPitch: PitchType,
                  extras: Extras?,
                  ornamentation: NoteTable.Ornamentation?) {
        //
        // Every entry point that can create a note with its written partner on the wrong side
        // checks it and throws; the transforms keep it by construction.
        //
        assert(!NoteTable.hasPartnerOnWrongSide(ornamentation, startPitch: startPitch))

        if let payload = Payload(extras: extras,
                                 ornamentation: ornamentation) {
            self = .extended(noteID, attack, duration, (startPitch, endPitch), payload)
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
        payload?.extras
    }

    internal var maximumPitch: PitchType {
        max(startPitch, endPitch)
    }

    internal var minimumPitch: PitchType {
        min(startPitch, endPitch)
    }

    internal var noteID: NoteID {
        switch self {
        case let .extended(noteID, _, _, _, _),
            let .glide(noteID, _, _, _),
            let .simple(noteID, _, _, _):
            noteID
        }
    }

    internal var ornamentation: NoteTable.Ornamentation? {
        payload?.ornamentation
    }

    internal var payload: Payload? {
        switch self {
        case let .extended(_, _, _, _, payload):
            payload

        default:
            nil
        }
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

extension NoteTable.StoredNote: Codable {

    // MARK: Internal Initializers

    //
    // Identity is never encoded (see `NoteID`'s doc comment), so decoding always
    // assigns a fresh one via the default parameter — indistinguishable from a
    // freshly inserted note. A written partner on the wrong side of the note is
    // rejected, as `insert` would reject it.
    //
    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let attack = try container.decode(TimeType.self)
        let duration = try container.decode(NoteTable.DurationType.self)
        let startPitch = try container.decode(PitchType.self)
        let endPitch = try container.decodeIfPresent(PitchType.self)
        let extras = try container.decodeIfPresent(Extras.self)?.normalizingNames()
        let ornamentation = try container.decodeIfPresent(NoteTable.Ornamentation.self)

        guard !NoteTable.hasPartnerOnWrongSide(ornamentation, startPitch: startPitch)
        else { throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                       debugDescription: "Ornament partner on the wrong side of the note")) }

        self.init(attack: attack,
                  duration: duration,
                  startPitch: startPitch,
                  endPitch: endPitch ?? startPitch,
                  extras: extras,
                  ornamentation: ornamentation)
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(attack)
        try container.encode(duration)
        try container.encode(startPitch)

        //
        // The decoder reads the optional elements in order, so a later one needs every earlier
        // slot written: `endPitch` before extras, and an extras slot (`null`) before the
        // ornamentation.
        //
        if endPitch != startPitch || payload != nil {
            try container.encode(endPitch)
        }

        if let extras {
            try container.encode(extras)
        } else if ornamentation != nil {
            try container.encodeNil()
        }

        if let ornamentation {
            try container.encode(ornamentation)
        }
    }
}

// MARK: - Comparable

extension NoteTable.StoredNote: Comparable {

    // MARK: Internal Type Methods

    internal static func < (lhs: Self,
                            rhs: Self) -> Bool {
        (lhs.attack, lhs.duration, rhs.startPitch, rhs.endPitch) < (rhs.attack, rhs.duration, lhs.startPitch, lhs.endPitch)
    }
}

// MARK: - Equatable

extension NoteTable.StoredNote: Equatable {

    // MARK: Internal Type Methods

    //
    // Identity is deliberately excluded: two notes are equal here exactly when
    // they carry the same attack, duration, pitches, extras, and ornamentation, regardless of
    // which `NoteID` each holds. Unlike the time-keyed maps, this equality is not
    // used to reject or collapse anything on insert — a note table allows exact
    // duplicates — but it keeps the same "content, not identity" contract the other
    // map types establish, and is what lets tests construct content-identical notes
    // independently and expect them equal.
    //
    internal static func == (lhs: Self,
                             rhs: Self) -> Bool {
        (lhs.attack, lhs.duration, lhs.startPitch, lhs.endPitch, lhs.extras, lhs.ornamentation) ==
            (rhs.attack, rhs.duration, rhs.startPitch, rhs.endPitch, rhs.extras, rhs.ornamentation)
    }
}

// MARK: - Sendable

extension NoteTable.StoredNote: Sendable {
}
