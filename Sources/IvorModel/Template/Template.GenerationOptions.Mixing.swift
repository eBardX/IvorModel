// © 2026 John Gary Pusey (see LICENSE.md)

extension Template.GenerationOptions {

    // MARK: Public Nested Types

    /// A way of mixing the recipe’s ``Template/GenerationOptions/order`` with another order.
    public enum Mixing {
        /// Blends the recipe’s order with another order at fixed weights. `weight` is the
        /// other order’s share, between 0 and 1 (exclusive); the recipe’s order gets the rest.
        /// For example, order 2 blended with order 1 at weight 0.3 is mostly faithful to the
        /// source, and sometimes wanders.
        case blend(with: Int, weight: Double)

        /// Morphs from the recipe’s order to another order over the given number of note
        /// events, following the given curve. For example, a morph from a high order to a low
        /// one starts faithful to the source and ends free.
        case morph(to: Int, over: Int, curve: Template.MorphCurve)
    }
}

// MARK: -

extension Template.GenerationOptions.Mixing {

    // MARK: Internal Instance Methods

    internal func validate(maximumOrder: Int) throws(Template.Error) {
        switch self {
        case let .blend(otherOrder, weight):
            guard (0...maximumOrder) ~= otherOrder
            else { throw .invalidOrder(maximumOrder) }

            guard weight.isFinite,
                  weight > 0,
                  weight < 1
            else { throw .invalidMixing }

        case let .morph(otherOrder, steps, curve):
            guard (0...maximumOrder) ~= otherOrder
            else { throw .invalidOrder(maximumOrder) }

            guard steps > 0,
                  curve.isValid
            else { throw .invalidMixing }
        }
    }
}

// MARK: - Codable

extension Template.GenerationOptions.Mixing: Codable {
}

// MARK: - Hashable

extension Template.GenerationOptions.Mixing: Hashable {
}

// MARK: - Sendable

extension Template.GenerationOptions.Mixing: Sendable {
}
