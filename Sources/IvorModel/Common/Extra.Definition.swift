// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Extra {

    // MARK: Public Nested Types

    /// A known extra, one Ivor attaches to the model: its name, what it’s attached to, and the
    /// associated values it carries (see ``Extra/definitions``).
    public struct Definition {

        // MARK: Public Initializers

        /// Creates a definition of a known extra.
        ///
        /// - Parameter name:               The extra’s name.
        /// - Parameter targets:            The kinds of model value the extra is attached to.
        /// - Parameter values:             The slots of the associated values the extra carries, in
        ///                                 order.
        ///                                 Defaults to none, for a bare flag.
        /// - Parameter minimumValueCount:  How many of `values` must be present; the rest may be
        ///                                 left off the end. Defaults to all of them.
        public init(name: Extra.Name,
                    targets: Set<Extra.Target>,
                    values: [Extra.ValueSlot] = [],
                    minimumValueCount: Int? = nil) {
            self.minimumValueCount = min(minimumValueCount ?? values.count, values.count)
            self.name = name
            self.targets = targets
            self.values = values
        }

        // MARK: Public Instance Properties

        /// How many of ``values`` must be present; the rest may be left off the end.
        public let minimumValueCount: Int

        /// The extra’s name.
        public let name: Extra.Name

        /// The kinds of model value the extra is attached to.
        public let targets: Set<Extra.Target>

        /// The slots of the associated values the extra carries, in order; empty for a bare flag.
        public let values: [Extra.ValueSlot]
    }
}

// MARK: -

extension Extra.Definition {

    // MARK: Public Instance Methods

    /// Returns a Boolean value indicating whether the given associated values are ones this
    /// extra accepts.
    ///
    /// - Parameter values: The associated values to check.
    ///
    /// - Returns:  `true` if there are at least ``minimumValueCount`` and at most as many as
    ///             ``values``, and each meets its slot’s specification; `false` otherwise.
    public func accepts(_ values: [Extra.AssociatedValue]) -> Bool {
        guard (minimumValueCount...self.values.count).contains(values.count)
        else { return false }

        return zip(self.values, values).allSatisfy { $0.accepts($1) }
    }
}

// MARK: - Hashable

extension Extra.Definition: Hashable {
}

// MARK: - Sendable

extension Extra.Definition: Sendable {
}
