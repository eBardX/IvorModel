// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

extension Template.State {

    // MARK: Public Nested Types

    /// What a state records of an event’s duration.
    public enum DurationValue {
        /// The duration itself.
        case absolute(TimeType.DurationType)

        /// The duration’s ratio to the previous event’s. The first event of a sequence has a
        /// ratio of 1, so it takes the duration that generation starts from.
        case relative(Number)
    }
}

// MARK: - Codable

extension Template.State.DurationValue: Codable {
}

// MARK: - Comparable

extension Template.State.DurationValue: Comparable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the first value comes before the second:
    /// absolute before relative, then by value.
    ///
    /// - Parameter lhs:    The left-hand value.
    /// - Parameter rhs:    The right-hand value.
    ///
    /// - Returns:  `true` if `lhs` comes before `rhs`; otherwise, `false`.
    public static func < (lhs: Self,
                          rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.absolute(lhs), .absolute(rhs)):
            lhs < rhs

        case let (.relative(lhs), .relative(rhs)):
            lhs < rhs

        case (.absolute, .relative):
            true

        case (.relative, .absolute):
            false
        }
    }
}

// MARK: - Hashable

extension Template.State.DurationValue: Hashable {
}

// MARK: - Sendable

extension Template.State.DurationValue: Sendable {
}
