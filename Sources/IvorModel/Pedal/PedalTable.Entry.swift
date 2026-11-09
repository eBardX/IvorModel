// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension PedalTable {

    // MARK: Public Nested Types

    /// A snapshot of an entry in a ``PedalTable``.
    ///
    /// There is deliberately no public initializer. Values of this type come only from an
    /// ``PedalTable``, so the ``entryID`` of one identifies an entry in that table — until that
    /// entry is removed — and can be passed back to methods such as
    /// ``PedalTable/remove(entryID:)``.
    public struct Entry {

        // MARK: Public Instance Properties

        /// The stable identity of the entry.
        public let entryID: EntryID

        /// The extra data attached to the entry, if any.
        public let extras: Extras?

        /// The level of the entry.
        public let level: Pedal.Level

        /// The time at which the level takes effect.
        public let time: TimeType

        // MARK: Internal Initializers

        internal init(_ entry: StoredEntry) {
            self.entryID = entry.entryID
            self.extras = entry.extras
            self.level = entry.level
            self.time = entry.time
        }
    }
}

// MARK: - Equatable

extension PedalTable.Entry: Equatable {
}

// MARK: - Sendable

extension PedalTable.Entry: Sendable {
}
