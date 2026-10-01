// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension DynamicMap {

    // MARK: Public Nested Types

    /// A snapshot of an entry in a ``DynamicMap``.
    ///
    /// There is deliberately no public initializer. Values of this type come only from a
    /// ``DynamicMap``, so the ``entryID`` of one identifies an entry in that map — until that entry
    /// is removed — and can be passed back to methods such as ``DynamicMap/remove(entryID:)``.
    public struct Entry {

        // MARK: Public Instance Properties

        /// The dynamic level of the entry.
        public let dynamic: Dynamic

        /// The stable identity of the entry.
        public let entryID: EntryID

        /// The extra data attached to the entry, if any.
        public let extras: Extras?

        /// The time at which the dynamic level takes effect.
        public let time: TimeType

        // MARK: Internal Initializers

        internal init(_ entry: StoredEntry) {
            self.dynamic = entry.dynamic
            self.entryID = entry.entryID
            self.extras = entry.extras
            self.time = entry.time
        }
    }
}

// MARK: - Equatable

extension DynamicMap.Entry: Equatable {
}

// MARK: - Sendable

extension DynamicMap.Entry: Sendable {
}
