// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

/// A pitch type that a template can analyze in relative terms: as pitch classes, or as intervals
/// from the previous pitch.
///
/// ``Frequency``, ``NoteNumber`` and ``Pitch`` conform.
public protocol TemplatePitch: PitchProtocol {

    // MARK: Public Associated Types

    /// The type of a pitch’s class: what it shares with every pitch whole octaves away.
    associatedtype PitchClassType: Codable, Comparable, Hashable, Sendable

    // MARK: Public Instance Properties

    /// This pitch’s class.
    var pitchClass: PitchClassType { get }

    // MARK: Public Instance Methods

    /// Returns the pitch of the given class that is nearest to this one.
    ///
    /// - Parameter pitchClass: The pitch class to find.
    ///
    /// - Returns:  The nearest pitch of that class, or `nil` if there is none in range.
    func nearest(_ pitchClass: PitchClassType) -> Self?

    /// Returns this pitch moved by a number of octaves.
    ///
    /// - Parameter octaves:    The number of octaves to move by: up if positive, down if
    ///                         negative.
    ///
    /// - Returns:  The moved pitch, or `nil` if it is out of range.
    func shifted(octaves: Int) -> Self?

    /// Returns the directed interval from this pitch to another, as a template records it.
    ///
    /// Intervals that a template should treat as the same are equal: for ``Frequency``, the
    /// ratio is rounded to the nearest cent. Otherwise, this is ``PitchProtocol/interval(to:)``.
    ///
    /// - Parameter pitch:  The target pitch.
    ///
    /// - Returns:  The directed interval, or `nil` if it cannot be determined.
    func templateInterval(to pitch: Self) -> DirectedInterval<IntervalType>?
}

// MARK: -

extension TemplatePitch {

    // MARK: Public Instance Methods

    /// Returns the directed interval from this pitch to another: ``PitchProtocol/interval(to:)``.
    ///
    /// - Parameter pitch:  The target pitch.
    ///
    /// - Returns:  The directed interval, or `nil` if it cannot be determined.
    public func templateInterval(to pitch: Self) -> DirectedInterval<IntervalType>? {
        interval(to: pitch)
    }
}
