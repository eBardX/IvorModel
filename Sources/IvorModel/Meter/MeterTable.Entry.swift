// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiTools

extension MeterTable {

    // MARK: Public Nested Types

    /// A snapshot of an entry in a ``MeterTable``.
    ///
    /// There is deliberately no public initializer. Values of this type come only from a
    /// ``MeterTable``, so the ``entryID`` of one identifies an entry in that table — until that
    /// entry is removed — and can be passed back to methods such as
    /// ``MeterTable/remove(entryID:)``.
    public struct Entry {

        // MARK: Public Instance Properties

        /// The beat time at which the entry starts a new bar.
        public let beatTime: BeatTime

        /// The stable identity of the entry.
        public let entryID: EntryID

        /// The extra data attached to the entry, if any.
        public let extras: Extras?

        /// The meter in effect from the entry on.
        public let meter: Meter

        // MARK: Internal Initializers

        internal init(_ entry: StoredEntry) {
            self.beatTime = entry.beatTime
            self.entryID = entry.entryID
            self.extras = entry.extras
            self.meter = entry.meter
        }
    }
}

// MARK: - Equatable

extension MeterTable.Entry: Equatable {
}

// MARK: - Sendable

extension MeterTable.Entry: Sendable {
}
