// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension Template.AnalysisOptions {

    // MARK: Public Nested Types

    /// A way of aligning a part’s attack and release times before it is sliced into note events.
    public enum TimingTolerance {
        /// Quantizes attack and release times to the nearest subdivision given by `factors`, as
        /// ``NoteTable/quantize(to:noteIDs:)`` does. For beat-time works only.
        case grid(factors: [Int])

        /// Merges attack and release times that lie within the given window of the first time in
        /// their group: each moves to that first time. A note that would then have no length
        /// keeps one window’s length. For wall-time works only.
        case window(WallDuration)
    }
}

// MARK: -

extension Template.AnalysisOptions.TimingTolerance {

    // MARK: Internal Instance Methods

    internal func validate() throws(Template.Error) {
        switch self {
        case let .grid(factors):
            guard !factors.isEmpty,
                  factors.allSatisfy({ $0 > 0 })
            else { throw .invalidTolerance }

        case let .window(window):
            guard !window.isZero
            else { throw .invalidTolerance }
        }
    }
}

// MARK: - Codable

extension Template.AnalysisOptions.TimingTolerance: Codable {
}

// MARK: - Hashable

extension Template.AnalysisOptions.TimingTolerance: Hashable {
}

// MARK: - Sendable

extension Template.AnalysisOptions.TimingTolerance: Sendable {
}
