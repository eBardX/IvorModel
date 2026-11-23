// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension Work.Rendering {

    // MARK: Public Nested Types

    /// How much later a rendered work sounds than written, so that nothing starts before time
    /// zero.
    ///
    /// In a beat work, everything moves later and the pickup grows by this much, or one is
    /// created; the first full bar still starts on the same music (a pickup that would reach a
    /// full bar adds a bar instead). In a wall work, everything simply moves later.
    public enum LeadIn {

        /// The lead-in of a beat work, in whole notes.
        case beat(BeatDuration)

        /// The lead-in of a wall work.
        case wall(WallDuration)
    }
}

// MARK: - Equatable

extension Work.Rendering.LeadIn: Equatable {
}

// MARK: - Sendable

extension Work.Rendering.LeadIn: Sendable {
}
