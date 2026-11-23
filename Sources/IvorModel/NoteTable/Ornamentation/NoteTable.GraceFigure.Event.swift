// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

extension NoteTable.GraceFigure {

    // MARK: Public Nested Types

    /// One event of a grace figure: a grace note, or a grace chord of several pitches.
    ///
    /// The ``pitches`` and ``length`` are the sign; the ``execution``, if any, is how this
    /// event is played, overriding the figure’s.
    public struct Event {

        // MARK: Public Initializers

        /// Creates a grace event, returning `nil` unless `pitches` is non-empty, sorted
        /// ascending, and free of duplicates.
        ///
        /// - Parameter pitches:    The pitches of the event; more than one is a grace chord.
        /// - Parameter length:     The written value in a beat work, or the performed length in
        ///                         a wall work, or `nil` if none is given. Defaults to `nil`.
        /// - Parameter execution:  How this event is played, or `nil` to follow the figure.
        ///                         Defaults to `nil`.
        public init?(pitches: [PitchType],
                     length: PositiveDuration<NoteTable.DurationType>? = nil,
                     execution: NoteTable.GraceExecution? = nil) {
            guard NoteTable.isPitchSet(pitches)
            else { return nil }

            self.execution = execution
            self.length = length
            self.pitches = pitches
        }

        // MARK: Public Instance Properties

        /// How this event is played, or `nil` to follow the figure. Part of the execution.
        public let execution: NoteTable.GraceExecution?

        /// The written value in a beat work, or the performed length in a wall work, or `nil`
        /// if none is given. Part of the sign.
        public let length: PositiveDuration<NoteTable.DurationType>?

        /// The pitches of the event, sorted ascending with no duplicates; more than one is a
        /// grace chord. Part of the sign.
        public let pitches: [PitchType]

        // MARK: Private Initializers

        private init(unchecked pitches: [PitchType],
                     length: PositiveDuration<NoteTable.DurationType>?,
                     execution: NoteTable.GraceExecution?) {
            self.execution = execution
            self.length = length
            self.pitches = pitches
        }
    }
}

// MARK: -

extension NoteTable.GraceFigure.Event {

    // MARK: Public Instance Methods

    /// Returns this event with each pitch transformed, sorted again, and with any duplicates
    /// removed.
    ///
    /// - Parameter transform:  The pitch mapping, such as a transposition.
    ///
    /// - Returns:  The mapped event.
    ///
    /// - Throws:   Any error that `transform` throws.
    public func mapPitches(_ transform: (PitchType) throws -> PitchType) rethrows -> Self {
        try Self(unchecked: NoteTable.pitchSet(pitches.map(transform)),
                 length: length,
                 execution: execution)
    }

    /// Returns this event with its written durations scaled by a factor, or `nil` if a scaled
    /// duration is zero or can’t be computed.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled event, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        var length = length
        var execution = execution

        if let value = length {
            guard let scaled = value.scaled(by: factor)
            else { return nil }

            length = scaled
        }

        if let value = execution {
            guard let scaled = value.scaled(by: factor)
            else { return nil }

            execution = scaled
        }

        return Self(unchecked: pitches,
                    length: length,
                    execution: execution)
    }
}

// MARK: - Codable

extension NoteTable.GraceFigure.Event: Codable {

    // MARK: Public Initializers

    /// Creates a grace event by decoding a positional array, `[pitches, length?, execution?]`,
    /// throwing a `DecodingError` if the pitches aren’t valid.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let pitches = try container.decode([PitchType].self)
        let length = try container.decodeIfPresent(PositiveDuration<NoteTable.DurationType>.self)
        let execution = try container.decodeIfPresent(NoteTable.GraceExecution.self)

        guard let value = Self(pitches: pitches,
                               length: length,
                               execution: execution)
        else { throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                       debugDescription: "Grace pitches must be non-empty, sorted and unique")) }

        self = value
    }

    // MARK: Public Instance Methods

    /// Encodes this grace event as a positional array, `[pitches, length?, execution?]`,
    /// leaving out trailing fields that are `nil`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(pitches)

        if let length {
            try container.encode(length)
        } else if execution != nil {
            try container.encodeNil()
        }

        if let execution {
            try container.encode(execution)
        }
    }
}

// MARK: - Hashable

extension NoteTable.GraceFigure.Event: Hashable {
}

// MARK: - Sendable

extension NoteTable.GraceFigure.Event: Sendable {
}
