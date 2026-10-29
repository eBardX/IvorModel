// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension Template.AnalysisOptions {

    // MARK: Public Nested Types

    /// A way of making near-identical note event durations the same.
    public enum DurationTolerance {
        /// Groups durations, shortest first, so that the longest in each group is at most
        /// `1 + fraction` times the shortest, and replaces each with its group’s most common
        /// duration (the shortest of those, on a tie). For example, 0.05 groups durations within
        /// 5% of each other. `fraction` must be positive and finite. For either time basis.
        case proportional(Double)

        /// Rounds each duration to the nearest multiple of the step, but never below one step.
        /// For wall-time works only.
        case step(WallDuration)
    }
}

// MARK: -

extension Template.AnalysisOptions.DurationTolerance {

    // MARK: Internal Instance Methods

    internal func validate() throws(Template.Error) {
        switch self {
        case let .proportional(fraction):
            guard fraction.isFinite,
                  fraction > 0
            else { throw .invalidTolerance }

        case let .step(step):
            guard !step.isZero
            else { throw .invalidTolerance }
        }
    }
}

// MARK: - Codable

extension Template.AnalysisOptions.DurationTolerance: Codable {
}

// MARK: - Hashable

extension Template.AnalysisOptions.DurationTolerance: Hashable {
}

// MARK: - Sendable

extension Template.AnalysisOptions.DurationTolerance: Sendable {
}
