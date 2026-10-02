// © 2026 John Gary Pusey (see LICENSE.md)

private import XestiTools

/// A copyright or other rights notice.
///
/// A public-domain statement or a licence (e.g. `"CC BY 4.0"`) is also a rights notice.
public struct RightsNotice {

    // MARK: Public Initializers

    /// Creates a rights notice, or returns `nil` if `text` is empty once its whitespace is
    /// normalized.
    ///
    /// - Parameter text:   The notice. Its whitespace is normalized line by line, so its line
    ///                     breaks are kept.
    /// - Parameter scope:  What the notice covers, or `nil` if it covers the work as a whole or
    ///                     the source doesn’t say. Defaults to `nil`.
    public init?(text: String,
                 scope: Scope? = nil) {
        guard let text = text.normalizingWhitespace(lineByLine: true).nilIfEmpty
        else { return nil }

        self.scope = scope
        self.text = text
    }

    // MARK: Public Instance Properties

    /// What the notice covers, or `nil` if it covers the work as a whole or the source doesn’t
    /// say.
    public let scope: Scope?

    /// The notice as given, with whitespace normalized but line breaks kept (e.g.
    /// `"© 1998 Acme Music"`).
    public let text: String
}

// MARK: - Codable

extension RightsNotice: Codable {

    // MARK: Public Initializers

    /// Creates a rights notice by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted, including text
    ///             that is empty once its whitespace is normalized.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let scope = try container.decodeIfPresent(Scope.self,
                                                  forKey: .scope)

        let text = try container.decode(String.self,
                                        forKey: .text)

        guard let notice = Self(text: text,
                                scope: scope)
        else { throw DecodingError.dataCorruptedError(forKey: .text,
                                                      in: container,
                                                      debugDescription: "Empty rights notice text") }

        self = notice
    }

    // MARK: Public Instance Methods

    /// Encodes this rights notice into the provided encoder.
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

        try container.encodeIfPresent(scope,
                                      forKey: .scope)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case scope
        case text
    }
}

// MARK: - Hashable

extension RightsNotice: Hashable {
}

// MARK: - Sendable

extension RightsNotice: Sendable {
}
