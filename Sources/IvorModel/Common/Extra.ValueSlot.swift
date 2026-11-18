// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Extra {

    // MARK: Public Nested Types

    /// One associated value of a known extra: what it represents, and what it must be (see
    /// ``Extra/Definition``).
    public struct ValueSlot {

        // MARK: Public Initializers

        /// Creates a slot for one associated value of a known extra.
        ///
        /// - Parameter role:   What the value represents.
        /// - Parameter spec:   What the value must be.
        public init(_ role: Extra.ValueRole,
                    _ spec: Extra.ValueSpec) {
            self.role = role
            self.spec = spec
        }

        // MARK: Public Instance Properties

        /// What the value represents.
        public let role: Extra.ValueRole

        /// What the value must be.
        public let spec: Extra.ValueSpec
    }
}

// MARK: -

extension Extra.ValueSlot {

    // MARK: Public Instance Methods

    /// Returns a Boolean value indicating whether the given associated value meets this slot’s
    /// ``spec``.
    ///
    /// - Parameter value:  The associated value to check.
    ///
    /// - Returns:  `true` if `value` meets ``spec``; `false` otherwise.
    public func accepts(_ value: Extra.AssociatedValue) -> Bool {
        spec.accepts(value)
    }
}

// MARK: - Hashable

extension Extra.ValueSlot: Hashable {
}

// MARK: - Sendable

extension Extra.ValueSlot: Sendable {
}
