// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension NoteTable {

    // MARK: Public Nested Types

    /// A snapshot of a note in a ``NoteTable``.
    ///
    /// There is deliberately no public initializer. Values of this type come only from a
    /// ``NoteTable``, so the ``noteID`` of one identifies a note in that table — until that note
    /// is removed — and can be passed back to methods such as ``NoteTable/remove(noteID:)``.
    public struct Note {

        // MARK: Public Instance Properties

        /// The attack time of the note.
        public let attack: TimeType

        /// The duration of the note.
        public let duration: DurationType

        /// The pitch at the end of the note; the same as ``startPitch`` unless the note glides.
        public let endPitch: PitchType

        /// The extra data attached to the note, if any.
        public let extras: Extras?

        /// The stable identity of the note.
        public let noteID: NoteID

        /// The pitch at the start of the note.
        public let startPitch: PitchType

        // MARK: Internal Initializers

        internal init(_ note: StoredNote) {
            self.attack = note.attack
            self.duration = note.duration
            self.endPitch = note.endPitch
            self.extras = note.extras
            self.noteID = note.noteID
            self.startPitch = note.startPitch
        }
    }
}

// MARK: - Equatable

extension NoteTable.Note: Equatable {
}

// MARK: - Sendable

extension NoteTable.Note: Sendable {
}
