// © 2026 John Gary Pusey (see LICENSE.md)

extension Work.Problem {

    // MARK: Public Nested Types

    /// What a ``Work/Problem`` is.
    public enum Kind {

        /// A fermata on a note while another part attacks during the note, so it isn’t clear
        /// how much of the music the hold covers. A warning: rendering holds the whole note. A
        /// fermata mark over the intended span says it exactly.
        case ambiguousHoldSpan

        /// The tones of one rolled chord — sharing an attack and an ``ArpeggioGroup`` — disagree
        /// on direction or execution. An error: rendering follows the first tone (lowest part,
        /// then lowest pitch).
        case conflictingArpeggio

        /// Fermatas starting at one moment, in different parts or places, hold for different
        /// lengths, and not all of them say so explicitly. A warning: rendering holds the
        /// longest.
        case conflictingDefaultHolds

        /// Fermatas starting at one moment each set an explicit hold, and the holds differ. An
        /// error: rendering holds the longest.
        case conflictingExplicitHolds

        /// A grace figure’s events take their own time from both sides of the main note in an
        /// order that can’t be played: before a figure’s main note, the events that take time
        /// from the note before must come first; after it, the events that take time from the
        /// note after must come last. A warning: rendering plays the events in their written
        /// order over the time they take together.
        case unorderedGraceAmounts
    }
}

// MARK: - Hashable

extension Work.Problem.Kind: Hashable {
}

// MARK: - Sendable

extension Work.Problem.Kind: Sendable {
}
