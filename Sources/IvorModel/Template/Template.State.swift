// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension Template {

    // MARK: Public Nested Types

    /// What a template records of one note event, as its ``AnalysisOptions/StateRecipe`` chooses.
    ///
    /// With the exact recipe, a state is the event’s pitches and duration. With relative
    /// features, it is intervals, pitch classes or a duration ratio, which generation turns back
    /// into notes from where the previous event left off.
    public struct State<TimeType: TimeProtocol, PitchType: TemplatePitch> where TimeType.DurationType: TemplateDuration {

        // MARK: Public Initializers

        /// Creates a new state.
        ///
        /// - Parameter isRest:     Whether the event is a rest.
        /// - Parameter duration:   What the state records of the event’s duration, or `nil` if
        ///                         it records nothing.
        /// - Parameter pitches:    What the state records of the event’s pitches, or `nil` if
        ///                         it records nothing or the event is a rest.
        public init(isRest: Bool,
                    duration: DurationValue?,
                    pitches: PitchValue?) {
            self.duration = duration
            self.isRest = isRest
            self.pitches = pitches
        }

        // MARK: Public Instance Properties

        /// What the state records of the event’s duration, or `nil` if it records nothing.
        public let duration: DurationValue?

        /// Whether the event is a rest. Recorded even when the state records nothing of pitch.
        public let isRest: Bool

        /// What the state records of the event’s pitches, or `nil` if it records nothing or the
        /// event is a rest.
        public let pitches: PitchValue?
    }
}

// MARK: - Codable

extension Template.State: Codable {
}

// MARK: - Comparable

extension Template.State: Comparable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the first state comes before the second: notes
    /// before rests, then by duration, then by pitches, with nothing recorded first.
    ///
    /// The ordering is for sorting states consistently; it has no musical meaning.
    ///
    /// - Parameter lhs:    The left-hand state.
    /// - Parameter rhs:    The right-hand state.
    ///
    /// - Returns:  `true` if `lhs` comes before `rhs`; otherwise, `false`.
    public static func < (lhs: Self,
                          rhs: Self) -> Bool {
        if lhs.isRest != rhs.isRest {
            return !lhs.isRest
        }

        if lhs.duration != rhs.duration {
            return _precedes(lhs.duration, rhs.duration)
        }

        return _precedes(lhs.pitches, rhs.pitches)
    }

    // MARK: Private Type Methods

    private static func _precedes<Value: Comparable>(_ lhs: Value?,
                                                     _ rhs: Value?) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            lhs < rhs

        case (nil, _?):
            true

        default:
            false
        }
    }
}

// MARK: - Hashable

extension Template.State: Hashable {
}

// MARK: - Sendable

extension Template.State: Sendable {
}
