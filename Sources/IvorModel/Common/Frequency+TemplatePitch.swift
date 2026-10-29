// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

private import Foundation
private import XestiNumbers

extension Frequency: TemplatePitch {

    // MARK: Public Instance Properties

    /// This frequency’s position within its octave, in whole cents above A (A4 = 440 Hz), from 0
    /// to 1199.
    public var pitchClass: Int {
        let cents = Int(_centsFromA4.rounded())

        return ((cents % 1_200) + 1_200) % 1_200
    }

    // MARK: Public Instance Methods

    /// Returns the frequency of the given class that is nearest to this one.
    ///
    /// - Parameter pitchClass: The position within an octave, in cents above A.
    ///
    /// - Returns:  The nearest frequency of that class, or `nil` if it is out of range.
    public func nearest(_ pitchClass: Int) -> Self? {
        let octaves = ((_centsFromA4 - Double(pitchClass)) / 1_200).rounded()

        return Self._fromCentsFromA4(Double(pitchClass) + octaves * 1_200)
    }

    /// Returns this frequency moved by a number of octaves.
    ///
    /// - Parameter octaves:    The number of octaves to move by.
    ///
    /// - Returns:  The moved frequency, or `nil` if it is out of range.
    public func shifted(octaves: Int) -> Self? {
        Self(numberValue: Number(doubleValue * pow(2, Double(octaves))))
    }

    /// Returns the directed interval from this frequency to another, with its ratio rounded to the
    /// nearest cent.
    ///
    /// - Parameter pitch:  The target frequency.
    ///
    /// - Returns:  The directed interval, or `nil` if it cannot be determined.
    public func templateInterval(to pitch: Self) -> DirectedInterval<Ratio>? {
        let cents = (1_200 * log2(pitch.doubleValue / doubleValue)).rounded()

        guard let ratio = Ratio(numberValue: Number(pow(2, abs(cents) / 1_200)))
        else { return nil }

        return DirectedInterval(interval: ratio,
                                direction: cents > 0 ? .ascending : cents < 0 ? .descending : .same)
    }

    // MARK: Private Type Methods

    private static func _fromCentsFromA4(_ cents: Double) -> Self? {
        Self(numberValue: Number(440 * pow(2, cents / 1_200)))
    }

    // MARK: Private Instance Properties

    private var _centsFromA4: Double {
        1_200 * log2(doubleValue / 440)
    }
}
