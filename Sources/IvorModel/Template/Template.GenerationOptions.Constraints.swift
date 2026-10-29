// © 2026 John Gary Pusey (see LICENSE.md)

extension Template.GenerationOptions {

    // MARK: Public Nested Types

    /// Which note events generation may choose. A note event that fails any constraint is never
    /// chosen; if every candidate fails, generation stops there, unless back-off finds a
    /// candidate at a lower order.
    public struct Constraints {

        // MARK: Public Initializers

        /// Creates a new set of constraints. With the defaults, every note event is allowed.
        ///
        /// - Parameter pitchRange:         The range every pitch must lie in, or `nil` for any
        ///                                 range. Defaults to `nil`.
        /// - Parameter allowedPitches:     The pitches allowed, such as a scale spelled out in
        ///                                 every octave, or `nil` for any pitch. Defaults to
        ///                                 `nil`.
        /// - Parameter maximumDuration:    The longest duration allowed, or `nil` for any
        ///                                 duration. Defaults to `nil`.
        /// - Parameter allowsRests:        Whether rests are allowed. Defaults to `true`.
        public init(pitchRange: ClosedRange<PitchType>? = nil,
                    allowedPitches: Set<PitchType>? = nil,
                    maximumDuration: DurationType? = nil,
                    allowsRests: Bool = true) {
            self.allowedPitches = allowedPitches
            self.allowsRests = allowsRests
            self.maximumDuration = maximumDuration
            self.pitchRange = pitchRange
        }

        // MARK: Public Instance Properties

        /// The pitches allowed, or `nil` for any pitch.
        public var allowedPitches: Set<PitchType>?

        /// Whether rests are allowed.
        public var allowsRests: Bool

        /// The longest duration allowed, or `nil` for any duration.
        public var maximumDuration: DurationType?

        /// The range every pitch must lie in, or `nil` for any range.
        public var pitchRange: ClosedRange<PitchType>?
    }
}

// MARK: -

extension Template.GenerationOptions.Constraints {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether these constraints allow every note event.
    public var isEmpty: Bool {
        allowedPitches == nil && allowsRests && maximumDuration == nil && pitchRange == nil
    }

    // MARK: Public Instance Methods

    /// Returns a Boolean value indicating whether these constraints allow the given note event.
    ///
    /// - Parameter noteEvent:  The note event to test.
    ///
    /// - Returns:  `true` if every pitch of `noteEvent` and its duration are allowed.
    public func allows(_ noteEvent: NoteEvent<TimeType, PitchType>) -> Bool {
        if noteEvent.tiedPitches.isEmpty, !allowsRests {
            return false
        }

        if let maximumDuration, noteEvent.duration > maximumDuration {
            return false
        }

        return noteEvent.tiedPitches.allSatisfy { tiedPitch in
            (pitchRange?.contains(tiedPitch.pitch) ?? true)
                && (allowedPitches?.contains(tiedPitch.pitch) ?? true)
        }
    }
}

// MARK: - Codable

extension Template.GenerationOptions.Constraints: Codable {
}

// MARK: - Hashable

extension Template.GenerationOptions.Constraints: Hashable {
}

// MARK: - Sendable

extension Template.GenerationOptions.Constraints: Sendable {
}
