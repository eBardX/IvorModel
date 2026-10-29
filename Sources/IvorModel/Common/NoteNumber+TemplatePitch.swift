// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

extension NoteNumber: TemplatePitch {

    // MARK: Public Instance Properties

    /// This note number’s position within its octave, from 0 (C) to 11 (B).
    public var pitchClass: Int {
        Int(uintValue % 12)
    }

    // MARK: Public Instance Methods

    /// Returns the note number of the given class that is nearest to this one, the lower on a tie.
    ///
    /// - Parameter pitchClass: The position within an octave, from 0 (C) to 11 (B).
    ///
    /// - Returns:  The nearest note number of that class, or `nil` if there is none in range.
    public func nearest(_ pitchClass: Int) -> Self? {
        let value = Int(uintValue)
        let base = value - self.pitchClass + pitchClass

        return [base - 12, base, base + 12]
            .filter { $0 >= 0 }
            .min { abs($0 - value) < abs($1 - value) }
            .flatMap { Self(uintValue: UInt($0)) }
    }

    /// Returns this note number moved by a number of octaves.
    ///
    /// - Parameter octaves:    The number of octaves to move by.
    ///
    /// - Returns:  The moved note number, or `nil` if it is out of range.
    public func shifted(octaves: Int) -> Self? {
        let value = Int(uintValue) + 12 * octaves

        guard value >= 0
        else { return nil }

        return Self(uintValue: UInt(value))
    }
}
