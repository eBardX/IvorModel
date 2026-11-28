// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Work.Scope {

    // MARK: Public Nested Types

    /// What a note must satisfy to be found by ``Work/scope(matching:within:)``: a time range,
    /// a pitch range, or both. A note that straddles a range’s bound counts or not as
    /// ``TimeMatch`` and ``PitchMatch`` say; a note is never split at a bound.
    public struct Criteria<TimeType: TimeProtocol, PitchType: PitchProtocol> {

        // MARK: Public Initializers

        /// Creates criteria.
        ///
        /// - Parameter timeRange:  The range a note’s time must fall within, or `nil` (the
        ///                         default) for any time.
        /// - Parameter timeMatch:  Which of the note’s times to test. Defaults to
        ///                         ``Work/Scope/TimeMatch/attack``.
        /// - Parameter pitchRange: The range a note’s pitch must fall within, or `nil` (the
        ///                         default) for any pitch.
        /// - Parameter pitchMatch: Which of the note’s pitches to test. Defaults to
        ///                         ``Work/Scope/PitchMatch/either``.
        public init(timeRange: ClosedRange<TimeType>? = nil,
                    timeMatch: TimeMatch = .attack,
                    pitchRange: ClosedRange<PitchType>? = nil,
                    pitchMatch: PitchMatch = .either) {
            self.pitchMatch = pitchMatch
            self.pitchRange = pitchRange
            self.timeMatch = timeMatch
            self.timeRange = timeRange
        }

        // MARK: Public Instance Properties

        /// Which of a note’s pitches to test.
        public var pitchMatch: PitchMatch

        /// The range a note’s pitch must fall within, or `nil` for any pitch.
        public var pitchRange: ClosedRange<PitchType>?

        /// Which of a note’s times to test.
        public var timeMatch: TimeMatch

        /// The range a note’s time must fall within, or `nil` for any time.
        public var timeRange: ClosedRange<TimeType>?
    }
}

// MARK: -

extension Work.Scope.Criteria {

    // MARK: Public Instance Methods

    /// Returns a Boolean value indicating whether a note satisfies these criteria.
    ///
    /// - Parameter note:   The note to test.
    ///
    /// - Returns:  `true` if the note satisfies both the time range and the pitch range.
    public func matches(_ note: NoteTable<TimeType, PitchType>.Note) -> Bool {
        if let timeRange {
            switch timeMatch {
            case .attack:
                guard timeRange.contains(note.attack)
                else { return false }

            case .sounding:
                guard note.attack <= timeRange.upperBound,
                      note.release >= timeRange.lowerBound
                else { return false }
            }
        }

        if let pitchRange {
            switch pitchMatch {
            case .either:
                return pitchRange.contains(note.startPitch) || pitchRange.contains(note.endPitch)

            case .end:
                return pitchRange.contains(note.endPitch)

            case .start:
                return pitchRange.contains(note.startPitch)
            }
        }

        return true
    }
}

// MARK: - Equatable

extension Work.Scope.Criteria: Equatable {
}

// MARK: - Hashable

extension Work.Scope.Criteria: Hashable {
}

// MARK: - Sendable

extension Work.Scope.Criteria: Sendable {
}
