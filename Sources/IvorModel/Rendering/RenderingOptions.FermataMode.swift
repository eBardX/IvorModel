// © 2026 John Gary Pusey (see LICENSE.md)

extension RenderingOptions {

    // MARK: Public Nested Types

    /// How rendering turns fermata holds and caesura pauses into time.
    public enum FermataMode {

        /// The holds and pauses aren’t rendered: the timeline is unchanged.
        case notRealized

        /// The time is inserted at each moment, and every later event moves later, at the
        /// written tempo.
        case stretchedNotes

        /// In a beat work, the tempo slows over each held span, so the bar grid is kept. A wall
        /// work, which has no tempo map, inserts the time instead.
        case tempoChanges
    }
}

// MARK: - Equatable

extension RenderingOptions.FermataMode: Equatable {
}

// MARK: - Sendable

extension RenderingOptions.FermataMode: Sendable {
}
