// © 2026 John Gary Pusey (see LICENSE.md)

extension Template {
    /// Metrics describing how a template’s Markov chain was trained.
    ///
    /// Apart from ``recommendedOrder`` and ``stateCount``, which describe the
    /// Markov chain as a whole, these metrics are drawn from its trained order
    /// (``order``) — the order used to generate new works from the template —
    /// rather than averaged or summed across every order it tracks.
    public struct Metrics {

        // MARK: Public Instance Properties

        /// The proportion of predecessor sequences at the trained order that
        /// lead to two or more distinct possible successors, in `0.0...1.0`.
        ///
        /// Near `1.0` means generation makes genuine probabilistic choices
        /// throughout; near `0.0` means most outcomes are deterministic.
        public let branchingRatio: Double

        /// The trained order: the template’s ``Template/maximumOrder``.
        public let order: Int

        /// The highest order greater than `0` at which the Markov chain is
        /// adequately trained for generation, or `nil` if there is no such
        /// order.
        public let recommendedOrder: Int?

        /// The number of distinct states observed across all training.
        public let stateCount: Int

        /// The total number of transitions recorded at the trained order.
        public let transitionCount: Int
    }
}

// MARK: - Equatable

extension Template.Metrics: Equatable {
}

// MARK: - Sendable

extension Template.Metrics: Sendable {
}
