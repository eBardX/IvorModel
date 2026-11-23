// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

extension NoteTable.OrnamentExecution {

    // MARK: Public Nested Types

    /// How fast an ornament alternates: a fixed rate, or a written note value.
    public enum Rate {

        /// Notes of this written value in a beat work, or this performed length in a wall work,
        /// such as a trill in thirty-seconds. It converts and scales with the note.
        case noteValue(PositiveDuration<NoteTable.DurationType>)

        /// This many notes per second, whatever the tempo.
        case perSecond(NotesPerSecond)
    }
}

// MARK: -

extension NoteTable.OrnamentExecution.Rate {

    // MARK: Public Instance Methods

    /// Returns this rate with a note value scaled by a factor, or `nil` if the scaled value is
    /// zero or can’t be computed. A rate per second is unchanged.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled rate, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        switch self {
        case let .noteValue(duration):
            duration.scaled(by: factor).map { .noteValue($0) }

        case .perSecond:
            self
        }
    }
}

// MARK: - Codable

extension NoteTable.OrnamentExecution.Rate: Codable {

    // MARK: Public Initializers

    /// Creates a rate by decoding its one case, `{"noteValue": d}` or `{"perSecond": n}`.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CaseCodingKey.self)
        let key = try CaseCodingKey.caseKey(of: container, typeName: "Rate")

        switch key.stringValue {
        case Self.noteValueKey:
            self = try .noteValue(container.decode(PositiveDuration<NoteTable.DurationType>.self, forKey: key))

        case Self.perSecondKey:
            self = try .perSecond(container.decode(NotesPerSecond.self, forKey: key))

        default:
            throw CaseCodingKey.unknownCase(key, in: container, typeName: "Rate")
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this rate as its one case, `{"noteValue": d}` or `{"perSecond": n}`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CaseCodingKey.self)

        switch self {
        case let .noteValue(duration):
            try container.encode(duration, forKey: CaseCodingKey(Self.noteValueKey))

        case let .perSecond(rate):
            try container.encode(rate, forKey: CaseCodingKey(Self.perSecondKey))
        }
    }

    // MARK: Private Type Properties

    private static var noteValueKey: String {
        "noteValue"
    }

    private static var perSecondKey: String {
        "perSecond"
    }
}

// MARK: - Hashable

extension NoteTable.OrnamentExecution.Rate: Hashable {
}

// MARK: - Sendable

extension NoteTable.OrnamentExecution.Rate: Sendable {
}
