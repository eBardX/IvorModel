// © 2026 John Gary Pusey (see LICENSE.md)

extension Patch {

    // MARK: Public Nested Types

    /// The kind of sound a ``Patch`` selects, and the numbers that select it.
    ///
    /// Program numbers run from 1 to 128, matching the conventions of the MIDI ``Extra`` values
    /// (such as ``Extra/midiProgram``); a custom bank runs from 0 to 16,383, and a variation
    /// from 0 to 127. Only a ``Patch`` checks that they’re in range.
    public enum Kind {
        /// A custom patch, such as one on a hardware synthesizer that doesn’t follow General MIDI,
        /// selected by its program and, optionally, its bank.
        ///
        /// - Parameter program:    The program number (1–128).
        /// - Parameter bank:       The bank number (0–16,383), sent as its most significant
        ///                         7 bits (Control Change 0, bank MSB) and its least
        ///                         significant 7 bits (Control Change 32, bank LSB) — so bank
        ///                         MSB *m* with LSB *l* is bank *m* × 128 + *l* — or `nil` to
        ///                         send no bank select.
        /// - Parameter name:       A name for the patch, for display only, or `nil`.
        case custom(program: Int, bank: Int?, name: String?)

        /// A General MIDI Level 1 instrument.
        ///
        /// - Parameter program:    The General MIDI program number (1–128).
        case generalMIDI1(program: Int)

        /// The General MIDI Level 1 percussion kit, which plays on channel 10.
        case generalMIDI1Percussion

        /// A General MIDI Level 2 instrument: a General MIDI program, or one of its variations.
        ///
        /// - Parameter program:    The General MIDI program number (1–128).
        /// - Parameter variation:  The variation (bank LSB, 0–127), where `0` is the General MIDI
        ///                         Level 1 instrument itself.
        case generalMIDI2(program: Int, variation: Int)

        /// A General MIDI Level 2 drum set.
        ///
        /// - Parameter program:    The program number (1–128) that selects the drum set.
        case generalMIDI2DrumSet(program: Int)
    }
}

// MARK: - Codable

extension Patch.Kind: Codable {
}

// MARK: - Hashable

extension Patch.Kind: Hashable {
}

// MARK: - Sendable

extension Patch.Kind: Sendable {
}
