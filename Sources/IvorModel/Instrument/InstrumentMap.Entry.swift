// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension InstrumentMap {

    // MARK: Public Nested Types

    /// A snapshot of an entry in an ``InstrumentMap``.
    ///
    /// There is deliberately no public initializer. Values of this type come only from an
    /// ``InstrumentMap``, so the ``entryID`` of one identifies an entry in that map — until that
    /// entry is removed — and can be passed back to methods such as
    /// ``InstrumentMap/remove(entryID:)``.
    public struct Entry {

        // MARK: Public Instance Properties

        /// The stable identity of the entry.
        public let entryID: EntryID

        /// The extra data attached to the entry, if any.
        public let extras: Extras?

        /// The instrument of the entry.
        public let instrument: Instrument

        /// The time at which the instrument takes effect.
        public let time: TimeType

        // MARK: Internal Initializers

        internal init(_ entry: StoredEntry) {
            self.entryID = entry.entryID
            self.extras = entry.extras
            self.instrument = entry.instrument
            self.time = entry.time
        }
    }
}

// MARK: - Equatable

extension InstrumentMap.Entry: Equatable {
}

// MARK: - Sendable

extension InstrumentMap.Entry: Sendable {
}
