// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiTools

extension KeyTable {

    // MARK: Public Nested Types

    /// A snapshot of an entry in a ``KeyTable``.
    ///
    /// There is deliberately no public initializer. Values of this type come only from a
    /// ``KeyTable``, so the ``entryID`` of one identifies an entry in that table — until
    /// that entry is removed — and can be passed back to methods such as
    /// ``KeyTable/remove(entryID:)``.
    public struct Entry {

        // MARK: Public Instance Properties

        /// The beat time at which the entry’s key takes effect.
        public let beatTime: BeatTime

        /// The stable identity of the entry.
        public let entryID: EntryID

        /// The extra data attached to the entry, if any.
        public let extras: Extras?

        /// The key in effect from the entry on.
        public let key: Key

        // MARK: Internal Initializers

        internal init(_ entry: StoredEntry) {
            self.beatTime = entry.beatTime
            self.entryID = entry.entryID
            self.extras = entry.extras
            self.key = entry.key
        }
    }
}

// MARK: - Equatable

extension KeyTable.Entry: Equatable {
}

// MARK: - Sendable

extension KeyTable.Entry: Sendable {
}
