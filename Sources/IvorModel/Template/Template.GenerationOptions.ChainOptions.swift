// © 2026 John Gary Pusey (see LICENSE.md)

extension Template.GenerationOptions {

    // MARK: Public Nested Types

    /// How one Markov chain is generated from: its order, mixed or not with another order, and
    /// its contrast.
    ///
    /// The recipe’s own ``Template/GenerationOptions/order``,
    /// ``Template/GenerationOptions/mixing`` and ``Template/GenerationOptions/contrast`` apply
    /// to a joint template’s chain, or to a separated template’s duration chain; a separated
    /// template’s pitch chain can have its own (see ``Template/GenerationOptions/pitchChain``).
    public struct ChainOptions {

        // MARK: Public Initializers

        /// Creates new chain options.
        ///
        /// - Parameter order:      The Markov order to generate at. Defaults to 1.
        /// - Parameter mixing:     How to mix `order` with another order. Defaults to `nil`.
        /// - Parameter contrast:   How strongly to favour common paths. Defaults to 1.
        public init(order: Int = 1,
                    mixing: Mixing? = nil,
                    contrast: Double = 1) {
            self.contrast = contrast
            self.mixing = mixing
            self.order = order
        }

        // MARK: Public Instance Properties

        /// How strongly to favour common paths: above 1 keeps to common paths, below 1 favours
        /// rare ones, and 1 leaves the chain’s probabilities unchanged. Must be positive and
        /// finite.
        public var contrast: Double

        /// How to mix ``order`` with another order, or `nil` to generate at ``order`` alone. A
        /// morph counts the chain’s own states: a pitch chain counts sounding events only.
        public var mixing: Mixing?

        /// The Markov order to generate at: the number of preceding states that choose the next.
        /// Must be between 0 and the template’s maximum order.
        public var order: Int
    }
}

// MARK: -

extension Template.GenerationOptions.ChainOptions {

    // MARK: Internal Instance Properties

    //
    // The highest order the chain generates at, from which back-off descends.
    //
    internal var topOrder: Int {
        switch mixing {
        case let .blend(otherOrder, _),
             let .morph(otherOrder, _, _):
            max(order, otherOrder)

        case nil:
            order
        }
    }

    // MARK: Internal Instance Methods

    internal func validate(maximumOrder: Int) throws(Template.Error) {
        guard (0...maximumOrder) ~= order
        else { throw .invalidOrder(maximumOrder) }

        guard contrast.isFinite,
              contrast > 0
        else { throw .invalidContrast }

        try mixing?.validate(maximumOrder: maximumOrder)
    }
}

// MARK: - Codable

extension Template.GenerationOptions.ChainOptions: Codable {
}

// MARK: - Hashable

extension Template.GenerationOptions.ChainOptions: Hashable {
}

// MARK: - Sendable

extension Template.GenerationOptions.ChainOptions: Sendable {
}
