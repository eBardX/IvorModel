// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTuning

// MARK: - RenderablePitch

extension Pitch: RenderablePitch {

    // MARK: Internal Instance Methods

    //
    // A diatonic step is the next letter up (or the one before, down) with the accidental the
    // key's signature gives that letter (resolution 7 of the grace-notes plan): no IvorTuning
    // interval is involved. With no key, or an atonal one, it's a whole tone instead
    // (resolution 6). The accidental comes from the key's `accidentals`, which every kind of key
    // lists; `Key.Signature` only describes custom signatures.
    //
    internal func partner(on side: PartnerSide,
                          rule: PartnerRule,
                          key: Key?) -> Self? {
        let interval: Interval

        switch rule {
        case .diatonic:
            if let step = _diatonicStep(on: side,
                                        key: key) {
                return step
            }

            interval = .major2

        case .halfStep:
            interval = .minor2

        case .wholeStep:
            interval = .major2
        }

        return transposed(by: DirectedInterval(interval: interval,
                                               direction: side == .above ? .ascending : .descending))
    }

    // MARK: Private Type Properties

    private static let letters: [Letter] = [.c, .d, .e, .f, .g, .a, .b]

    //
    // Semitones above C of each letter, in `letters` order.
    //
    private static let letterSemitones = [0, 2, 4, 5, 7, 9, 11]

    // MARK: Private Instance Properties

    //
    // How high this pitch sounds, in semitones from C in octave 0, so that, say, B♯4 and C5
    // sound the same.
    //
    private var soundingSemitones: Int {
        let index = Self.letters.firstIndex(of: letter) ?? 0

        return octave.intValue * 12 + Self.letterSemitones[index] + accidental.order
    }

    // MARK: Private Instance Methods

    private func _diatonicStep(on side: PartnerSide,
                               key: Key?) -> Self? {
        guard let key,
              key != .atonal,
              let index = Self.letters.firstIndex(of: letter)
        else { return nil }

        let isAbove = side == .above
        let newIndex = (index + (isAbove ? 1 : 6)) % 7
        let octaveChange = isAbove ? (index == 6 ? 1 : 0) : (index == 0 ? -1 : 0)
        let newLetter = Self.letters[newIndex]

        guard let newOctave = Octave(intValue: octave.intValue + octaveChange)
        else { return nil }

        let accidental = key.accidentals.first { $0.letter == newLetter }?.accidental ?? .natural
        let step = Self(pitchClass: PitchClass(letter: newLetter,
                                               accidental: accidental),
                        octave: newOctave)

        //
        // A key can make the diatonic step land on or past the main pitch (a B♯ main note in a
        // key with B♭, say); a whole tone is used then instead.  `Pitch`'s `<` orders by how
        // pitches are written, so they're compared by how they sound.
        //
        let stepSemitones = step.soundingSemitones
        let mainSemitones = soundingSemitones

        guard isAbove ? stepSemitones > mainSemitones : stepSemitones < mainSemitones
        else { return nil }

        return step
    }
}
