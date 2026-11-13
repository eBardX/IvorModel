// © 2026 John Gary Pusey (see LICENSE.md)

extension MeterTable {

    // MARK: Public Nested Types

    /// A position of an entry in a ``MeterTable``.
    ///
    /// Opaque rather than a plain `Int`, so that a position is never mistaken for a bar number or a
    /// beat time. Like an array index, a position is valid only until the meter table is next
    /// modified; to keep addressing an entry across edits, use its ``MeterTable/Entry/entryID``.
    public struct Index {

        // MARK: Internal Initializers

        internal init(_ offset: Int) {
            self.offset = offset
        }

        // MARK: Internal Instance Properties

        internal let offset: Int
    }
}

// MARK: - Comparable

extension MeterTable.Index: Comparable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the left position precedes the right.
    ///
    /// - Parameter lhs:    The left-hand position.
    /// - Parameter rhs:    The right-hand position.
    ///
    /// - Returns:  `true` if `lhs` comes before `rhs`.
    public static func < (lhs: Self,
                          rhs: Self) -> Bool {
        lhs.offset < rhs.offset
    }
}

// MARK: - Hashable

extension MeterTable.Index: Hashable {
}

// MARK: - Sendable

extension MeterTable.Index: Sendable {
}
