// © 2026 John Gary Pusey (see LICENSE.md)

extension Template {

    // MARK: Public Nested Types

    /// The rate at which a morph moves from one order to another.
    public enum MorphCurve {
        /// Slow at both ends and fastest in the middle, following half a cosine wave.
        case cosine

        /// A steady rate.
        case linear

        /// Slow at both ends and fast in the middle, following a logistic (S-shaped) curve.
        /// Higher steepness makes the middle faster. Must be positive and finite.
        case logistic(steepness: Double)

        /// Proportional to a power of the progress: above 1 starts slow and ends fast, below 1
        /// starts fast and ends slow. Must be positive and finite.
        case power(Double)
    }
}

// MARK: -

extension Template.MorphCurve {

    // MARK: Internal Instance Properties

    internal var isValid: Bool {
        switch self {
        case .cosine,
             .linear:
            true

        case let .logistic(value),
             let .power(value):
            value.isFinite && value > 0
        }
    }
}

// MARK: - Codable

extension Template.MorphCurve: Codable {
}

// MARK: - Hashable

extension Template.MorphCurve: Hashable {
}

// MARK: - Sendable

extension Template.MorphCurve: Sendable {
}
