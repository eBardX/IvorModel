// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

extension Pitch: TemplatePitch {

    // MARK: Public Instance Methods

    /// Returns the pitch of the given class that is nearest to this one, by semitones in equal
    /// temperament, the lower on a tie.
    ///
    /// - Parameter pitchClass: The pitch class to find.
    ///
    /// - Returns:  The nearest pitch of that class, or `nil` if there is none in range.
    public func nearest(_ pitchClass: PitchClass) -> Self? {
        let semitones = _semitones

        return (-1...1)
            .compactMap { Octave(intValue: octave.intValue + $0) }
            .map { Self(pitchClass: pitchClass, octave: $0) }
            .min { abs($0._semitones - semitones) < abs($1._semitones - semitones) }
    }

    /// Returns this pitch moved by a number of octaves.
    ///
    /// - Parameter octaves:    The number of octaves to move by.
    ///
    /// - Returns:  The moved pitch, or `nil` if it is out of range.
    public func shifted(octaves: Int) -> Self? {
        Octave(intValue: octave.intValue + octaves).map {
            Self(pitchClass: pitchClass,
                 octave: $0)
        }
    }

    // MARK: Private Instance Properties

    //
    // Semitones above C in octave 0, in equal temperament, so that B♯3 and C4 are the same — for
    // finding the nearest pitch of a class, not for ordering pitches.
    //
    private var _semitones: Int {
        let letterSemitones = [0, 2, 4, 5, 7, 9, 11]

        return 12 * octave.intValue + letterSemitones[letter.order - 1] + accidental.order
    }
}
