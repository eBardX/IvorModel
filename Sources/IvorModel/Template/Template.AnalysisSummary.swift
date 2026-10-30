// © 2026 John Gary Pusey (see LICENSE.md)

extension Template {

    // MARK: Public Nested Types

    /// What an analysis made of its ``AnalysisOptions/Variants``: how many sequences it trained,
    /// and which variants it didn’t.
    public struct AnalysisSummary {

        // MARK: Public Initializers

        /// Creates a new analysis summary.
        ///
        /// - Parameter sequenceCount:      The number of sequences trained. Defaults to 1.
        /// - Parameter mergedCount:        The number of variants not trained because their
        ///                                 states were the same as an earlier variant’s. Defaults
        ///                                 to 0.
        /// - Parameter skippedVariants:    The variants that couldn’t be made. Defaults to none.
        public init(sequenceCount: Int = 1,
                    mergedCount: Int = 0,
                    skippedVariants: [Variant] = []) {
            self.mergedCount = mergedCount
            self.sequenceCount = sequenceCount
            self.skippedVariants = skippedVariants
        }

        // MARK: Public Instance Properties

        /// The number of variants not trained because their states were the same as an earlier
        /// variant’s — a symmetric row’s, say, or a transposition when the template learns
        /// intervals.
        public let mergedCount: Int

        /// The number of sequences trained, the original included.
        public let sequenceCount: Int

        /// The variants that couldn’t be made — a transposition out of range, say — in the order
        /// they were tried.
        public let skippedVariants: [Variant]
    }
}

// MARK: - Codable

extension Template.AnalysisSummary: Codable {
}

// MARK: - Hashable

extension Template.AnalysisSummary: Hashable {
}

// MARK: - Sendable

extension Template.AnalysisSummary: Sendable {
}
