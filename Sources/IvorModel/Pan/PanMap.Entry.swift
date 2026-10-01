// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension PanMap {

    // MARK: Public Nested Types

    /// A snapshot of an entry in a ``PanMap``.
    ///
    /// There is deliberately no public initializer. Values of this type come only from a
    /// ``PanMap``, so the ``entryID`` of one identifies an entry in that map — until that entry
    /// is removed — and can be passed back to methods such as ``PanMap/remove(entryID:)``.
    public struct Entry {

        // MARK: Public Instance Properties

        /// The stable identity of the entry.
        public let entryID: EntryID

        /// The extra data attached to the entry, if any.
        public let extras: Extras?

        /// The pan position of the entry.
        public let pan: Pan

        /// The time at which the pan position takes effect.
        public let time: TimeType

        // MARK: Internal Initializers

        internal init(_ entry: StoredEntry) {
            self.entryID = entry.entryID
            self.extras = entry.extras
            self.pan = entry.pan
            self.time = entry.time
        }
    }
}

// MARK: - Equatable

extension PanMap.Entry: Equatable {
}

// MARK: - Sendable

extension PanMap.Entry: Sendable {
}
