// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

extension NoteTable.ArpeggioExecution {

    // MARK: Public Nested Types

    /// How far apart an arpeggio’s tones start.
    public enum Spread {

        /// The tones start this far apart: a written duration in a beat work, or a performed
        /// length in a wall work.
        case perTone(PositiveDuration<NoteTable.DurationType>)

        /// The whole roll takes this share of the chord’s shortest tone, so every tone still
        /// sounds.
        case total(Proportion)
    }
}

// MARK: -

extension NoteTable.ArpeggioExecution.Spread {

    // MARK: Public Instance Methods

    /// Returns this spread with a per-tone duration scaled by a factor, or `nil` if the scaled
    /// duration is zero or can’t be computed. A share is unchanged.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled spread, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        switch self {
        case let .perTone(duration):
            duration.scaled(by: factor).map { .perTone($0) }

        case .total:
            self
        }
    }
}

// MARK: - Codable

extension NoteTable.ArpeggioExecution.Spread: Codable {

    // MARK: Public Initializers

    /// Creates a spread by decoding its one case, `{"perTone": d}` or `{"total": p}`.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CaseCodingKey.self)
        let key = try CaseCodingKey.caseKey(of: container, typeName: "Spread")

        switch key.stringValue {
        case Self.perToneKey:
            self = try .perTone(container.decode(PositiveDuration<NoteTable.DurationType>.self, forKey: key))

        case Self.totalKey:
            self = try .total(container.decode(Proportion.self, forKey: key))

        default:
            throw CaseCodingKey.unknownCase(key, in: container, typeName: "Spread")
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this spread as its one case, `{"perTone": d}` or `{"total": p}`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CaseCodingKey.self)

        switch self {
        case let .perTone(duration):
            try container.encode(duration, forKey: CaseCodingKey(Self.perToneKey))

        case let .total(proportion):
            try container.encode(proportion, forKey: CaseCodingKey(Self.totalKey))
        }
    }

    // MARK: Private Type Properties

    private static var perToneKey: String {
        "perTone"
    }

    private static var totalKey: String {
        "total"
    }
}

// MARK: - Hashable

extension NoteTable.ArpeggioExecution.Spread: Hashable {
}

// MARK: - Sendable

extension NoteTable.ArpeggioExecution.Spread: Sendable {
}
