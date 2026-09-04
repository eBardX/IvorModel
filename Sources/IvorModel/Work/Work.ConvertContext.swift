// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

private import XestiNumbers
private import XestiTools

extension Work {
    /// A bundle of dependencies needed when converting a work between time bases or pitch notations.
    public struct ConvertContext {

        // MARK: Public Initializers

        /// Creates a convert context with all properties set to nil.
        public init() {
            self.keyboardMap = nil
            self.pitchSpeller = nil
            self.pitchStandard = nil
            self.tuningSystem = nil
        }

        // MARK: Public Instance Properties

        /// The keyboard map used for absolute ↔ keyboard pitch conversions.
        public let keyboardMap: KeyboardMap?

        /// The pitch speller used for absolute/keyboard → standard pitch conversions.
        public let pitchSpeller: (any PitchSpeller)?

        /// The pitch standard used for standard ↔ absolute pitch conversions.
        public let pitchStandard: PitchStandard?

        /// The tuning system used for standard ↔ absolute pitch conversions.
        public let tuningSystem: (any TuningSystem)?

        // MARK: Private Initializers

        private init(keyboardMap: KeyboardMap?,
                     pitchSpeller: (any PitchSpeller)?,
                     pitchStandard: PitchStandard?,
                     tuningSystem: (any TuningSystem)?) {
            self.keyboardMap = keyboardMap
            self.pitchSpeller = pitchSpeller
            self.pitchStandard = pitchStandard
            self.tuningSystem = tuningSystem
        }
    }
}

// MARK: -

extension Work.ConvertContext {

    // MARK: Public Type Properties

    /// The default convert context: 12-EDO, A4 = 440 Hz, Meredith pitch speller.
    public static let `default` = Work.ConvertContext()
        .keyboardMap(concertKeyboardMap)
        .pitchSpeller(MeredithPitchSpeller())
        .pitchStandard(.a440)
        .tuningSystem(EqualTemperament.edo12)

    // MARK: Public Instance Methods

    /// Returns a copy of this convert context with the given keyboard map.
    ///
    /// - Parameter keyboardMap:    The keyboard map used for absolute ↔
    ///                             keyboard pitch conversions.
    ///
    /// - Returns:  A new ``Work/ConvertContext`` with `keyboardMap` set.
    public func keyboardMap(_ keyboardMap: KeyboardMap) -> Work.ConvertContext {
        Work.ConvertContext(keyboardMap: keyboardMap,
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
        Work.ConvertContext(keyboardMap: keyboardMap,
                            pitchSpeller: pitchSpeller,
                            pitchStandard: pitchStandard,
                            tuningSystem: tuningSystem)
    }

    /// Returns a copy of this convert context with the given pitch standard.
    ///
    /// - Parameter pitchStandard:  The pitch standard used for standard ↔
    ///                             absolute pitch conversions.
    ///
    /// - Returns:  A new ``Work/ConvertContext`` with `pitchStandard` set.
    public func pitchStandard(_ pitchStandard: PitchStandard) -> Work.ConvertContext {
        Work.ConvertContext(keyboardMap: keyboardMap,
                            pitchSpeller: pitchSpeller,
                            pitchStandard: pitchStandard,
                            tuningSystem: tuningSystem)
    }

    /// Returns a copy of this convert context with the given tuning system.
    ///
    /// - Parameter tuningSystem:   The tuning system used for standard ↔
    ///                             absolute pitch conversions.
    ///
    /// - Returns:  A new ``Work/ConvertContext`` with `tuningSystem` set.
    public func tuningSystem(_ tuningSystem: any TuningSystem) -> Work.ConvertContext {
        Work.ConvertContext(keyboardMap: keyboardMap,
                            pitchSpeller: pitchSpeller,
                            pitchStandard: pitchStandard,
                            tuningSystem: tuningSystem)
    }

    // MARK: Private Type Properties

    private static let concertKeyboardMap = KeyboardMap(referenceNote: NoteNumber(uintValue: 69).require(),
                                                        referenceFrequency: 440,
                                                        middleNote: NoteNumber(uintValue: 60).require(),
                                                        equivalenceRatio: .octave,
                                                        ratios: (0..<12).map { Ratio(cents: Number($0) * 100) })
}

// MARK: - Sendable

extension Work.ConvertContext: Sendable {
}
