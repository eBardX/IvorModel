// © 2026 John Gary Pusey (see LICENSE.md)

extension NoteTable {

    // MARK: Public Nested Types

    /// A position of a note in a ``NoteTable``.
    ///
    /// Opaque rather than a plain `Int`, like the map types’ positions, so a position can’t be
    /// mistaken for an attack time or a note count. Like an array index, a position is valid only
    /// until the note table is next modified; to keep addressing a note across edits, use its
    /// ``NoteTable/Note/noteID``.
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

extension NoteTable.Index: Comparable {

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

extension NoteTable.Index: Hashable {
}

// MARK: - Sendable

extension NoteTable.Index: Sendable {
}
