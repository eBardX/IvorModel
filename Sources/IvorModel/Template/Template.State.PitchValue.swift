// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

extension Template.State {

    // MARK: Public Nested Types

    /// What a state records of a sounding event’s pitches.
    public enum PitchValue {
        /// The pitches themselves.
        case absolute([Template.Tone<PitchType>])

        /// The bass’s interval from the previous sounding bass, and the shape of the chord: each
        /// pitch’s interval above the bass, the bass itself (a unison) first. The first event of a
        /// sequence has a unison bass, so it starts on the pitch that generation starts from.
        case interval(bass: DirectedInterval<PitchType.IntervalType>,
                      shape: [Template.Tone<DirectedInterval<PitchType.IntervalType>>])

        /// The pitches’ classes, with octave doublings recorded once.
        case pitchClass([Template.Tone<PitchType.PitchClassType>])
    }
}

// MARK: - Codable

extension Template.State.PitchValue: Codable {
}

// MARK: - Comparable

extension Template.State.PitchValue: Comparable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the first value comes before the second:
    /// absolute, then interval, then pitch class, then by their tones.
    ///
    /// - Parameter lhs:    The left-hand value.
    /// - Parameter rhs:    The right-hand value.
    ///
    /// - Returns:  `true` if `lhs` comes before `rhs`; otherwise, `false`.
    public static func < (lhs: Self,
                          rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.absolute(lhs), .absolute(rhs)):
            return lhs.lexicographicallyPrecedes(rhs)

        case let (.interval(lhsBass, lhsShape), .interval(rhsBass, rhsShape)):
            if lhsBass != rhsBass {
                return lhsBass < rhsBass
            }

            return lhsShape.lexicographicallyPrecedes(rhsShape)

        case let (.pitchClass(lhs), .pitchClass(rhs)):
            return lhs.lexicographicallyPrecedes(rhs)

        default:
            return lhs._rank < rhs._rank
        }
    }

    // MARK: Private Instance Properties

    private var _rank: Int {
        switch self {
        case .absolute:
            0

        case .interval:
            1

        case .pitchClass:
            2
        }
    }
}

// MARK: - Hashable

extension Template.State.PitchValue: Hashable {
}

// MARK: - Sendable

extension Template.State.PitchValue: Sendable {
}
