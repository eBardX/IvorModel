// © 2026 John Gary Pusey (see LICENSE.md)

extension PanMap {

    // MARK: Public Nested Types

    /// A position of an entry in a ``PanMap``.
    ///
    /// Opaque rather than a plain `Int`, so that an integer literal such as `panMap[1]` still
    /// means the time passed to ``PanMap/subscript(_:)``, never a position. Like an array
    /// index, a position is valid only until the pan map is next modified; to keep addressing an
    /// entry across edits, use its ``PanMap/Entry/entryID``.
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

extension PanMap.Index: Comparable {

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

extension PanMap.Index: Hashable {
}

// MARK: - Sendable

extension PanMap.Index: Sendable {
}
