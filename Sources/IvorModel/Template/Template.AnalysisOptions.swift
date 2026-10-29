// © 2026 John Gary Pusey (see LICENSE.md)

extension Template {

    // MARK: Public Nested Types

    /// A recipe for analyzing a part into a template.
    ///
    /// Performed material almost never repeats a duration or a frequency exactly, so analyzing it
    /// exactly gives a template with about as many states as notes. The tolerances make
    /// near-identical states the same, in two stages:
    ///
    /// 1. ``timing`` aligns the part’s attack and release times before it is sliced into note
    ///    events, so that a chord whose notes start at slightly different times becomes one
    ///    event, not several very short ones.
    /// 2. ``durations`` and ``pitches`` then replace each note event’s duration and pitches with
    ///    a representative value.
    ///
    /// The defaults analyze exactly, as earlier versions did. The work being analyzed is never
    /// changed.
    public struct AnalysisOptions {

        // MARK: Public Initializers

        /// Creates a new analysis recipe.
        ///
        /// - Parameter maximumOrder:   The maximum pattern depth for the analysis.
        /// - Parameter timing:         How to align attack and release times before slicing.
        ///                             Defaults to `nil` (exact times).
        /// - Parameter durations:      How to make near-identical durations the same. Defaults
        ///                             to `nil` (exact durations).
        /// - Parameter pitches:        How to make near-identical pitches the same. Defaults to
        ///                             `nil` (exact pitches).
        public init(maximumOrder: Int,
                    timing: TimingTolerance? = nil,
                    durations: DurationTolerance? = nil,
                    pitches: PitchTolerance? = nil) {
            self.durations = durations
            self.maximumOrder = maximumOrder
            self.pitches = pitches
            self.timing = timing
        }

        // MARK: Public Instance Properties

        /// How to make near-identical durations the same, or `nil` for exact durations.
        public var durations: DurationTolerance?

        /// The maximum pattern depth for the analysis. Must be positive.
        public var maximumOrder: Int

        /// How to make near-identical pitches the same, or `nil` for exact pitches.
        public var pitches: PitchTolerance?

        /// How to align attack and release times before slicing, or `nil` for exact times.
        public var timing: TimingTolerance?
    }
}

// MARK: -

extension Template.AnalysisOptions {

    // MARK: Internal Instance Methods

    //
    // Checks the values themselves; whether each tolerance suits the work's time basis and pitch
    // notation is checked where the work's types are known — see `Template+Analyze.swift`.
    //
    internal func validate() throws(Template.Error) {
        guard maximumOrder > 0
        else { throw .invalidMaximumOrder }

        try timing?.validate()
        try durations?.validate()
        try pitches?.validate()
    }
}

// MARK: - Codable

extension Template.AnalysisOptions: Codable {
}

// MARK: - Hashable

extension Template.AnalysisOptions: Hashable {
}

// MARK: - Sendable

extension Template.AnalysisOptions: Sendable {
}
