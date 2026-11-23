// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

extension NoteTable {

    // MARK: Public Nested Types

    /// An amount of time a grace figure takes from a note: a share of that note, or a written
    /// duration.
    ///
    /// A share survives every transform and time-basis conversion unchanged. A duration is a
    /// written value in a beat work, or a performed length in a wall work, and converts with
    /// the note.
    public enum Amount {

        /// A written duration, or a performed length in a wall work.
        case duration(PositiveDuration<DurationType>)

        /// A share of the note the time comes from.
        case share(Proportion)
    }
}

// MARK: -

extension NoteTable.Amount {

    // MARK: Public Instance Methods

    /// Returns this amount with a duration scaled by a factor, or `nil` if the scaled duration
    /// is zero or can’t be computed. A share is unchanged.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled amount, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        switch self {
        case let .duration(duration):
            duration.scaled(by: factor).map { .duration($0) }

        case .share:
            self
        }
    }
}

// MARK: - Codable

extension NoteTable.Amount: Codable {

    // MARK: Public Initializers

    /// Creates an amount by decoding its one case, `{"duration": d}` or `{"share": p}`.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CaseCodingKey.self)
        let key = try CaseCodingKey.caseKey(of: container, typeName: "Amount")

        switch key.stringValue {
        case Self.durationKey:
            self = try .duration(container.decode(PositiveDuration<NoteTable.DurationType>.self, forKey: key))

        case Self.shareKey:
            self = try .share(container.decode(Proportion.self, forKey: key))

        default:
            throw CaseCodingKey.unknownCase(key, in: container, typeName: "Amount")
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this amount as its one case, `{"duration": d}` or `{"share": p}`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CaseCodingKey.self)

        switch self {
        case let .duration(duration):
            try container.encode(duration, forKey: CaseCodingKey(Self.durationKey))

        case let .share(proportion):
            try container.encode(proportion, forKey: CaseCodingKey(Self.shareKey))
        }
    }

    // MARK: Private Type Properties

    private static var durationKey: String {
        "duration"
    }

    private static var shareKey: String {
        "share"
    }
}

// MARK: - Hashable

extension NoteTable.Amount: Hashable {
}

// MARK: - Sendable

extension NoteTable.Amount: Sendable {
}
