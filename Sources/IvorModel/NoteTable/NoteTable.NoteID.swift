// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

private import Foundation

extension NoteTable {

    /// A stable identity for a single note in a ``NoteTable``, represented as a
    /// validated string.
    ///
    /// A note's attack time, duration, pitches, and extras can all change — via
    /// ``NoteTable/moveAttack(noteID:to:)``, ``NoteTable/moveDuration(noteID:to:)``,
    /// ``NoteTable/movePitchStart(noteID:to:)``, or ``NoteTable/movePitchEnd(noteID:to:)`` —
    /// without affecting its identity, so a caller can keep addressing the same note
    /// across an edit that reorders it, rather than recomputing which ordinal
    /// position it landed on.
    ///
    /// Not persisted: `NoteTable.Note`'s `Codable` conformance never encodes a
    /// note's identity, and assigns every decoded note a fresh one, the same as a
    /// newly inserted note. A note's identity is therefore stable only within one
    /// in-memory note table's lifetime — never across an encode/decode round trip,
    /// and so never across a save and reopen.
    ///
    /// Unlike the time-keyed maps' `EntryID`, identity here does the same job in a
    /// context where content isn't unique to begin with: a note table allows exact
    /// duplicates (a doubled unison), so — unlike `TempoMap`/`PanMap`/`DynamicMap`/
    /// `InstrumentMap` — a move here can never "merge into" a pre-existing duplicate;
    /// `noteID` always keeps naming the same note, with no survivor-identity case to
    /// account for.
    public struct NoteID: StringRepresentable {

        // MARK: Public Initializers

        /// Creates a new, unique note identity.
        public init() {
            self.init(Self.validPrefix + UUID().base62String)
        }

        /// Creates a note identity from a string value, returning `nil` if the
        /// string is invalid.
        ///
        /// - Parameter stringValue:    The string identifying the note.
        public init?(stringValue: String) {
            guard Self.isValid(stringValue)
            else { return nil }

            self.stringValue = stringValue
        }

        // MARK: Public Instance Properties

        /// The string value of this note identity.
        public let stringValue: String
    }
}

// MARK: -

extension NoteTable.NoteID {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given string is a valid note
    /// identity.
    ///
    /// - Parameter stringValue:    The string to validate.
    ///
    /// - Returns:  `true` if `stringValue` is valid; otherwise, `false`.
    public static func isValid(_ stringValue: String) -> Bool {
        stringValue.wholeMatch(of: validPattern) != nil
    }

    // MARK: Private Type Properties

    //
    // Computed, not stored — `NoteID` is nested inside the generic
    // `NoteTable<TimeType, PitchType>`, and Swift doesn't allow stored static
    // properties on a type nested in a generic context, even though this one
    // doesn't itself depend on `TimeType`/`PitchType`.
    //
    private static var validPattern: Regex<Substring> {
        /N\$[0-9A-Za-z]{22}/
    }

    private static var validPrefix: String {
        "N$"
    }
}
