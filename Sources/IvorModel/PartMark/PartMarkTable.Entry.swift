// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

extension PartMarkTable {

    // MARK: Public Nested Types

    /// A snapshot of an entry in a ``PartMarkTable``.
    ///
    /// There is deliberately no public initializer. Values of this type come only from a
    /// ``PartMarkTable``, so the ``entryID`` of one identifies an entry in that table — until that
    /// entry is removed — and can be passed back to methods such as
    /// ``PartMarkTable/remove(entryID:)``.
    public struct Entry {

        // MARK: Public Instance Properties

        /// The stable identity of the entry.
        public let entryID: EntryID

        /// The mark.
        public let mark: PartMark<TimeType>

        /// The time of the mark: a caesura’s moment, or the start of a fermata’s span.
        public let time: TimeType

        // MARK: Internal Initializers

        internal init(_ entry: StoredEntry) {
            self.entryID = entry.entryID
            self.mark = entry.mark
            self.time = entry.time
        }
    }
}

// MARK: - Equatable

extension PartMarkTable.Entry: Equatable {
}

// MARK: - Sendable

extension PartMarkTable.Entry: Sendable {
}
