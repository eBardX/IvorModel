// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

extension NoteTable {

    // MARK: Public Nested Types

    /// A grace figure: one or more grace notes or grace chords, before or after a main note.
    ///
    /// The ``events``, ``isSlashed`` and ``isTiedToMainNote`` are the sign; the
    /// ``execution``, if any, is how the figure is played. A figure lives on its main note, in
    /// the note’s ornamentation, so it moves, transposes and converts with it.
    public struct GraceFigure {

        // MARK: Public Initializers

        /// Creates a grace figure, returning `nil` if `events` is empty.
        ///
        /// - Parameter events:             The events of the figure, in playing order. Must not
        ///                                 be empty.
        /// - Parameter isSlashed:          Whether the figure is slashed (an acciaccatura).
        ///                                 Defaults to `false`.
        /// - Parameter isTiedToMainNote:   Whether the figure is tied to its main note: its last
        ///                                 event into the main note for a figure before it, or
        ///                                 the main note into its first event for a figure
        ///                                 after it. Defaults to `false`.
        /// - Parameter execution:          How the figure is played, or `nil` to follow the
        ///                                 rules. Defaults to `nil`.
        public init?(events: [Event],
                     isSlashed: Bool = false,
                     isTiedToMainNote: Bool = false,
                     execution: GraceExecution? = nil) {
            guard !events.isEmpty
            else { return nil }

            self.events = events
            self.execution = execution
            self.isSlashed = isSlashed
            self.isTiedToMainNote = isTiedToMainNote
        }

        // MARK: Public Instance Properties

        /// The events of the figure, in playing order; never empty. Part of the sign.
        public let events: [Event]

        /// How the figure is played, or `nil` to follow the rules. An event’s own execution
        /// overrides it. Part of the execution.
        public let execution: GraceExecution?

        /// A Boolean value indicating whether the figure is slashed (an acciaccatura). Part of
        /// the sign.
        public let isSlashed: Bool

        /// A Boolean value indicating whether the figure is tied to its main note: its last
        /// event into the main note for a figure before it, or the main note into its first
        /// event for a figure after it. Part of the sign.
        public let isTiedToMainNote: Bool

        // MARK: Private Initializers

        private init(unchecked events: [Event],
                     isSlashed: Bool,
                     isTiedToMainNote: Bool,
                     execution: GraceExecution?) {
            self.events = events
            self.execution = execution
            self.isSlashed = isSlashed
            self.isTiedToMainNote = isTiedToMainNote
        }
    }
}

// MARK: -

extension NoteTable.GraceFigure {

    // MARK: Public Instance Properties

    /// Every pitch of the figure, event by event in playing order.
    public var pitches: [PitchType] {
        events.flatMap(\.pitches)
    }

    // MARK: Public Instance Methods

    /// Returns this figure with each pitch transformed (see
    /// ``NoteTable/GraceFigure/Event/mapPitches(_:)``).
    ///
    /// - Parameter transform:  The pitch mapping, such as a transposition.
    ///
    /// - Returns:  The mapped figure.
    ///
    /// - Throws:   Any error that `transform` throws.
    public func mapPitches(_ transform: (PitchType) throws -> PitchType) rethrows -> Self {
        try Self(unchecked: events.map { try $0.mapPitches(transform) },
                 isSlashed: isSlashed,
                 isTiedToMainNote: isTiedToMainNote,
                 execution: execution)
    }

    /// Returns this figure as it reads on the other side of its main note: its events in the
    /// opposite order. A figure before a note reversed is the figure after it, and the reverse;
    /// a tie to the main note stays one, and the executions stay as they are (see
    /// ``NoteTable/GraceExecution/fromPrevious``).
    ///
    /// - Returns:  The reversed figure.
    public func reversed() -> Self {
        Self(unchecked: events.reversed(),
             isSlashed: isSlashed,
             isTiedToMainNote: isTiedToMainNote,
             execution: execution)
    }

    /// Returns this figure with its written durations scaled by a factor, or `nil` if a scaled
    /// duration is zero or can’t be computed.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled figure, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        var events: [Event] = []

        for event in self.events {
            guard let scaled = event.scaled(by: factor)
            else { return nil }

            events.append(scaled)
        }

        var execution = execution

        if let value = execution {
            guard let scaled = value.scaled(by: factor)
            else { return nil }

            execution = scaled
        }

        return Self(unchecked: events,
                    isSlashed: isSlashed,
                    isTiedToMainNote: isTiedToMainNote,
                    execution: execution)
    }
}

// MARK: - Codable

extension NoteTable.GraceFigure: Codable {

    // MARK: Public Initializers

    /// Creates a grace figure by decoding it, throwing a `DecodingError` if it has no events.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let events = try container.decode([Event].self, forKey: .events)
        let isSlashed = try container.decodeIfPresent(Bool.self, forKey: .isSlashed) ?? false
        let isTiedToMainNote = try container.decodeIfPresent(Bool.self, forKey: .isTiedToMainNote) ?? false
        let execution = try container.decodeIfPresent(NoteTable.GraceExecution.self, forKey: .execution)

        guard let value = Self(events: events,
                               isSlashed: isSlashed,
                               isTiedToMainNote: isTiedToMainNote,
                               execution: execution)
        else { throw DecodingError.dataCorruptedError(forKey: .events,
                                                      in: container,
                                                      debugDescription: "A grace figure must have at least one event") }

        self = value
    }

    // MARK: Public Instance Methods

    /// Encodes this grace figure, leaving out flags that are `false` and an execution that is
    /// `nil`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(events, forKey: .events)

        if isSlashed {
            try container.encode(true, forKey: .isSlashed)
        }

        if isTiedToMainNote {
            try container.encode(true, forKey: .isTiedToMainNote)
        }

        try container.encodeIfPresent(execution, forKey: .execution)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case events
        case execution
        case isSlashed = "slashed"
        case isTiedToMainNote = "tied"
    }
}

// MARK: - Hashable

extension NoteTable.GraceFigure: Hashable {
}

// MARK: - Sendable

extension NoteTable.GraceFigure: Sendable {
}
