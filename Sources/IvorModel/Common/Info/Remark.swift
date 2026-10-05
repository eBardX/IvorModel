// © 2026 John Gary Pusey (see LICENSE.md)

private import XestiTools

/// A free-form note about a work or part.
public struct Remark {

    // MARK: Public Initializers

    /// Creates a remark, or returns `nil` if `text` is empty once its whitespace is normalized.
    ///
    /// - Parameter text:   The text of the note. Its whitespace is normalized line by line, so
    ///                     its line breaks are kept.
    /// - Parameter label:  What kind of note this is, or `nil`. Its whitespace is normalized to a
    ///                     single line, and a label that is then empty becomes `nil`. Defaults to
    ///                     `nil`.
    public init?(text: String,
                 label: String? = nil) {
        guard let text = text.normalizingWhitespace(lineByLine: true).nilIfEmpty
        else { return nil }

        self.label = label?.normalizingWhitespace().nilIfEmpty
        self.text = text
    }

    // MARK: Public Instance Properties

    /// What kind of note this is (e.g. `"history"`, `"source"`), or `nil`, with whitespace
    /// normalized to a single line.
    public let label: String?

    /// The text of the note, with whitespace normalized but line breaks kept.
    public let text: String
}

// MARK: - Codable

extension Remark: Codable {

    // MARK: Public Initializers

    /// Creates a remark by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted, including text
    ///             that is empty once its whitespace is normalized.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let label = try container.decodeIfPresent(String.self,
                                                  forKey: .label)

        let text = try container.decode(String.self,
                                        forKey: .text)

        guard let remark = Self(text: text,
                                label: label)
        else { throw DecodingError.dataCorruptedError(forKey: .text,
                                                      in: container,
                                                      debugDescription: "Empty remark text") }

        self = remark
    }

    // MARK: Public Instance Methods

    /// Encodes this remark into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(text,
                             forKey: .text)

        try container.encodeIfPresent(label,
                                      forKey: .label)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case label
        case text
    }
}

// MARK: - Hashable

extension Remark: Hashable {
}

// MARK: - Sendable

extension Remark: Sendable {
}
