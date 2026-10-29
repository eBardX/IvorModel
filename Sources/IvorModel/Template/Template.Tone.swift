// © 2026 John Gary Pusey (see LICENSE.md)

extension Template {

    // MARK: Public Nested Types

    /// One pitch of a state — as a pitch, a pitch class or an interval — with its ties.
    public struct Tone<Value: Codable & Comparable & Hashable & Sendable> {

        // MARK: Public Initializers

        /// Creates a new tone.
        ///
        /// - Parameter value:      The pitch, pitch class or interval.
        /// - Parameter startsTie:  Whether the pitch is tied to the next event.
        /// - Parameter endsTie:    Whether the pitch is tied from the previous event.
        public init(value: Value,
                    startsTie: Bool,
                    endsTie: Bool) {
            self.endsTie = endsTie
            self.startsTie = startsTie
            self.value = value
        }

        // MARK: Public Instance Properties

        /// Whether the pitch is tied from the previous event.
        public let endsTie: Bool

        /// Whether the pitch is tied to the next event.
        public let startsTie: Bool

        /// The pitch, pitch class or interval.
        public let value: Value
    }
}

// MARK: - Codable

extension Template.Tone: Codable {
}

// MARK: - Comparable

extension Template.Tone: Comparable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the first tone comes before the second: by
    /// value, then by its ties.
    ///
    /// - Parameter lhs:    The left-hand tone.
    /// - Parameter rhs:    The right-hand tone.
    ///
    /// - Returns:  `true` if `lhs` comes before `rhs`; otherwise, `false`.
    public static func < (lhs: Self,
                          rhs: Self) -> Bool {
        if lhs.value != rhs.value {
            return lhs.value < rhs.value
        }

        return (lhs.startsTie ? 1 : 0, lhs.endsTie ? 1 : 0) < (rhs.startsTie ? 1 : 0, rhs.endsTie ? 1 : 0)
    }
}

// MARK: - Hashable

extension Template.Tone: Hashable {
}

// MARK: - Sendable

extension Template.Tone: Sendable {
}
