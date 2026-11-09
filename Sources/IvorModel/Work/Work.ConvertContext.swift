// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

extension Work {

    // MARK: Public Nested Types

    /// A bundle of dependencies needed when converting a work between time bases or pitch notations.
    ///
    /// A conversion uses only the dependencies it needs. For example, a raw keyboard layout
    /// (raw-ratio or frequency) tunes its own keys, so a conversion between `absolute` and
    /// `keyboard` with one doesn’t use the tuning system or pitch standard.
    public struct ConvertContext {

        // MARK: Public Initializers

        /// Creates a convert context with every dependency set to `nil` and key matching set to
        /// `.nearest`.
        public init() {
            self.keyboardLayout = nil
            self.keyMatching = .nearest
            self.pitchSpeller = nil
            self.pitchStandard = nil
            self.tuningSystem = nil
        }

        // MARK: Public Instance Properties

        /// The keyboard layout used for every conversion to or from keyboard pitch notation, and
        /// for `absolute → standard`.
        public let keyboardLayout: KeyboardLayout?

        /// How strictly a pitch must match a key in conversions that search for one:
        /// `standard → keyboard`, `absolute → keyboard`, and `absolute → standard`.
        public let keyMatching: KeyMatching

        /// The pitch speller used for absolute/keyboard → standard pitch conversions. Without one,
        /// a pitch-class keyboard layout spells each key with its own fixed name.
        public let pitchSpeller: (any PitchSpeller)?

        /// The pitch standard used to tune standard pitches and the keys of a pitch-class or
        /// degree keyboard layout.
        public let pitchStandard: PitchStandard?

        /// The tuning system used to tune standard pitches and the keys of a pitch-class or
        /// degree keyboard layout.
        public let tuningSystem: (any TuningSystem)?

        // MARK: Private Initializers

        private init(keyboardLayout: KeyboardLayout?,
                     keyMatching: KeyMatching,
                     pitchSpeller: (any PitchSpeller)?,
                     pitchStandard: PitchStandard?,
                     tuningSystem: (any TuningSystem)?) {
            self.keyboardLayout = keyboardLayout
            self.keyMatching = keyMatching
            self.pitchSpeller = pitchSpeller
            self.pitchStandard = pitchStandard
            self.tuningSystem = tuningSystem
        }
    }
}

// MARK: -

extension Work.ConvertContext {

    // MARK: Public Type Properties

    /// The default convert context: the piano keyboard layout, 12-EDO, A4 = 440 Hz, Meredith
    /// pitch speller, and nearest-key matching.
    public static let `default` = Work.ConvertContext()
        .keyboardLayout(.piano)
        .pitchSpeller(MeredithPitchSpeller())
        .pitchStandard(.a440)
        .tuningSystem(EqualTemperament.edo12)

    // MARK: Public Instance Methods

    /// Returns a copy of this convert context with the given keyboard layout.
    ///
    /// - Parameter keyboardLayout: The keyboard layout used for conversions involving keyboard
    ///                             pitch notation.
    ///
    /// - Returns:  A new ``Work/ConvertContext`` with `keyboardLayout` set.
    public func keyboardLayout(_ keyboardLayout: KeyboardLayout) -> Work.ConvertContext {
        Work.ConvertContext(keyboardLayout: keyboardLayout,
                            keyMatching: keyMatching,
                            pitchSpeller: pitchSpeller,
                            pitchStandard: pitchStandard,
                            tuningSystem: tuningSystem)
    }

    /// Returns a copy of this convert context with the given key matching.
    ///
    /// - Parameter keyMatching:    How strictly a pitch must match a key.
    ///
    /// - Returns:  A new ``Work/ConvertContext`` with `keyMatching` set.
    public func keyMatching(_ keyMatching: KeyMatching) -> Work.ConvertContext {
        Work.ConvertContext(keyboardLayout: keyboardLayout,
                            keyMatching: keyMatching,
                            pitchSpeller: pitchSpeller,
                            pitchStandard: pitchStandard,
                            tuningSystem: tuningSystem)
    }

    /// Returns a copy of this convert context with the given pitch speller.
    ///
    /// - Parameter pitchSpeller:   The pitch speller used for
    ///                             absolute/keyboard → standard pitch
    ///                             conversions.
    ///
    /// - Returns:  A new ``Work/ConvertContext`` with `pitchSpeller` set.
    public func pitchSpeller(_ pitchSpeller: any PitchSpeller) -> Work.ConvertContext {
        Work.ConvertContext(keyboardLayout: keyboardLayout,
                            keyMatching: keyMatching,
                            pitchSpeller: pitchSpeller,
                            pitchStandard: pitchStandard,
                            tuningSystem: tuningSystem)
    }

    /// Returns a copy of this convert context with the given pitch standard.
    ///
    /// - Parameter pitchStandard:  The pitch standard used to tune standard pitches and keyboard
    ///                             keys.
    ///
    /// - Returns:  A new ``Work/ConvertContext`` with `pitchStandard` set.
    public func pitchStandard(_ pitchStandard: PitchStandard) -> Work.ConvertContext {
        Work.ConvertContext(keyboardLayout: keyboardLayout,
                            keyMatching: keyMatching,
                            pitchSpeller: pitchSpeller,
                            pitchStandard: pitchStandard,
                            tuningSystem: tuningSystem)
    }

    /// Returns a copy of this convert context with the given tuning system.
    ///
    /// - Parameter tuningSystem:   The tuning system used to tune standard pitches and keyboard
    ///                             keys.
    ///
    /// - Returns:  A new ``Work/ConvertContext`` with `tuningSystem` set.
    public func tuningSystem(_ tuningSystem: any TuningSystem) -> Work.ConvertContext {
        Work.ConvertContext(keyboardLayout: keyboardLayout,
                            keyMatching: keyMatching,
                            pitchSpeller: pitchSpeller,
                            pitchStandard: pitchStandard,
                            tuningSystem: tuningSystem)
    }
}

// MARK: - Sendable

extension Work.ConvertContext: Sendable {
}
