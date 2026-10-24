// © 2026 John Gary Pusey (see LICENSE.md)

extension Patch {

    // MARK: Public Nested Types

    /// The kind of sound a ``Patch`` selects, and the numbers that select it.
    ///
    /// Program numbers run from 1 to 128, and bank numbers from 0 to 127, matching the
    /// conventions of the MIDI ``Extra`` values (such as ``Extra/midiProgram``). Only a
    /// ``Patch`` checks that they’re in range.
    public enum Kind {
        /// A custom patch, such as one on a hardware synthesizer that doesn’t follow General MIDI,
        /// selected by its program and, optionally, its bank.
        ///
        /// - Parameter program:    The program number (1–128).
        /// - Parameter bankMSB:    The bank number’s most significant byte (Control Change 0,
        ///                         0–127), or `nil` to send none.
        /// - Parameter bankLSB:    The bank number’s least significant byte (Control Change 32,
        ///                         0–127), or `nil` to send none.
        /// - Parameter name:       A name for the patch, for display only, or `nil`.
        case custom(program: Int, bankMSB: Int?, bankLSB: Int?, name: String?)

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
