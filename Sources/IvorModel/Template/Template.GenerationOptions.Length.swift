// © 2026 John Gary Pusey (see LICENSE.md)

private import IvorTiming

extension Template.GenerationOptions {

    // MARK: Public Nested Types

    /// An amount of generated music.
    public enum Length {
        /// A duration, in beats or seconds according to the template’s time basis. Generation
        /// stops at the first note event that reaches it, so the result may run slightly over.
        case duration(DurationType)

        /// A number of note events, including rests. Must be positive.
        case noteCount(Int)
    }
}

// MARK: -

extension Template.GenerationOptions.Length {

    // MARK: Internal Instance Properties

    internal var isValid: Bool {
        switch self {
        case let .duration(duration):
            !duration.isZero

        case let .noteCount(limit):
            limit > 0
        }
    }

    // MARK: Internal Instance Methods

    internal func isReached(noteCount: Int,
                            time: TimeType) -> Bool {
        switch self {
        case let .duration(duration):
            time >= TimeType.zero.moved(by: DirectedDuration(duration: duration,
                                                             direction: .forward)) ?? time

        case let .noteCount(limit):
            noteCount >= limit
        }
    }
}

// MARK: - Codable

extension Template.GenerationOptions.Length: Codable {
}

// MARK: - Hashable

extension Template.GenerationOptions.Length: Hashable {
}

// MARK: - Sendable

extension Template.GenerationOptions.Length: Sendable {
}
