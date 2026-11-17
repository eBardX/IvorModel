// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiTools

extension KeySignatureTable {

    // MARK: Public Nested Types

    /// A snapshot of an entry in a ``KeySignatureTable``.
    ///
    /// There is deliberately no public initializer. Values of this type come only from a
    /// ``KeySignatureTable``, so the ``entryID`` of one identifies an entry in that table — until
    /// that entry is removed — and can be passed back to methods such as
    /// ``KeySignatureTable/remove(entryID:)``.
    public struct Entry {

        // MARK: Public Instance Properties

        /// The beat time at which the entry’s key signature takes effect.
        public let beatTime: BeatTime

        /// The stable identity of the entry.
        public let entryID: EntryID

        /// The extra data attached to the entry, if any, such as ``Extra/keySignatureMode``.
        public let extras: Extras?

        /// The key signature in effect from the entry on.
        public let keySignature: KeySignature

        // MARK: Internal Initializers

        internal init(_ entry: StoredEntry) {
            self.beatTime = entry.beatTime
            self.entryID = entry.entryID
            self.extras = entry.extras
            self.keySignature = entry.keySignature
        }
    }
}

// MARK: - Equatable

extension KeySignatureTable.Entry: Equatable {
}

// MARK: - Sendable

extension KeySignatureTable.Entry: Sendable {
}
