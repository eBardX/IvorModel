// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Extra {

    // MARK: Public Nested Types

    /// What one associated value of a known extra must be (see ``Extra/Definition``).
    public enum ValueSpec {

        /// A `.bool`.
        case bool

        /// A `.double`, within `range` if one is given.
        case double(ClosedRange<Double>?)

        /// An `.int`, within `range` if one is given.
        case int(ClosedRange<Int>?)

        /// A finite `.double` greater than zero.
        case positiveDouble

        /// A `.string`, one of `choices` if they’re given.
        case string([String]?)
    }
}

// MARK: -

extension Extra.ValueSpec {

    // MARK: Public Instance Methods

    /// Returns a Boolean value indicating whether the given associated value meets this
    /// specification.
    ///
    /// - Parameter value:  The associated value to check.
    ///
    /// - Returns:  `true` if `value` has the specified type, and lies within its range or among
    ///             its choices, if any; `false` otherwise.
    public func accepts(_ value: Extra.AssociatedValue) -> Bool {
        switch (self, value) {
        case (.bool, .bool):
            true

        case let (.double(range), .double(value)):
            range?.contains(value) ?? true

        case let (.int(range), .int(value)):
            range?.contains(value) ?? true

        case let (.positiveDouble, .double(value)):
            value.isFinite && value > 0

        case let (.string(choices), .string(value)):
            choices?.contains(value) ?? true

        default:
            false
        }
    }
}

// MARK: - Hashable

extension Extra.ValueSpec: Hashable {
}

// MARK: - Sendable

extension Extra.ValueSpec: Sendable {
}
