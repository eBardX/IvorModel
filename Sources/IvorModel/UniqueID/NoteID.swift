// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

/// A stable identity for a single note in a ``NoteTable``, represented as a
/// validated string.
///
/// A note’s attack time, duration, pitches, and extras can all change — via
/// ``NoteTable/moveAttack(noteID:to:)``, ``NoteTable/moveDuration(noteID:to:)``,
/// ``NoteTable/movePitchStart(noteID:to:)``, or ``NoteTable/movePitchEnd(noteID:to:)`` —
/// without affecting its identity, so a caller can keep addressing the same note
/// across an edit that reorders it, rather than recomputing which ordinal
/// position it landed on.
///
/// Not persisted: `NoteTable.Note`’s `Codable` conformance never encodes a
/// note’s identity, and assigns every decoded note a fresh one, the same as a
/// newly inserted note. A note’s identity is therefore stable only within one
/// in-memory note table’s lifetime — never across an encode/decode round trip,
/// and so never across a save and reopen.
///
/// Unlike the time-keyed maps’ `EntryID`, identity here does the same job in a
/// context where content isn’t unique to begin with: a note table allows exact
/// duplicates (a doubled unison), so — unlike `TempoMap`/`PanMap`/`DynamicMap`/
/// `InstrumentMap` — a move here can never “merge into” a pre-existing duplicate;
/// `noteID` always keeps naming the same note, with no survivor-identity case to
/// account for.
///
/// A top-level, non-generic type — not nested inside `NoteTable<TimeType, PitchType>`
/// — so a single `NoteID` (and a single `Set<NoteID>`) can be shared across
/// differently-`PitchType`d parts, e.g. by `Work`'s whole-work transform methods,
/// which operate across all three beat-time `Content` cases in one function body.
public struct NoteID {

    // MARK: Public Initializers

    /// Creates a note identity from a string value already known to be valid.
    ///
    /// - Parameter stringValue:    The string identifying the note.
    public init(uncheckedStringValue stringValue: String) {
        self.stringValue = stringValue
    }

    // MARK: Public Instance Properties

    /// The string value of this note identity.
    public let stringValue: String
}

// MARK: - UniqueID

extension NoteID: UniqueID {

    // MARK: Public Type Properties

    public nonisolated(unsafe) static let validPattern = /N\$[0-9A-Za-z]{22}/

    public static let validPrefix = "N$"
}
