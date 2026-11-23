// © 2026 John Gary Pusey (see LICENSE.md)

extension PartMarkTable {

    // MARK: Public Nested Types

    /// A position of an entry in a ``PartMarkTable``.
    ///
    /// Opaque rather than a plain `Int`. Like an array index, a position is valid only until the
    /// table is next modified; to keep addressing an entry across edits, use its
    /// ``PartMarkTable/Entry/entryID``.
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

extension PartMarkTable.Index: Comparable {

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

extension PartMarkTable.Index: Hashable {
}

// MARK: - Sendable

extension PartMarkTable.Index: Sendable {
}
