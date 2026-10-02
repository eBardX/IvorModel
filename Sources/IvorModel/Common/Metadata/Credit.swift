// © 2026 John Gary Pusey (see LICENSE.md)

private import XestiTools

/// A person or group credited with a creative contribution.
public struct Credit {

    // MARK: Public Initializers

    /// Creates a credit, or returns `nil` if `name` is empty once its whitespace is normalized.
    ///
    /// - Parameter name:   The credited name. Its whitespace is normalized to a single line.
    /// - Parameter role:   The kind of contribution, or `nil` if the source does not say.
    ///                     Defaults to `nil`.
    public init?(name: String,
                 role: Role? = nil) {
        guard let name = name.normalizingWhitespace().nilIfEmpty
        else { return nil }

        self.name = name
        self.role = role
    }

    // MARK: Public Instance Properties

    /// The credited name, with whitespace normalized to a single line (e.g. `"Trad."`,
    /// `"J. S. Bach"`).
    public let name: String

    /// The kind of contribution, or `nil` if the source does not say.
    public let role: Role?
}

// MARK: - Codable

extension Credit: Codable {

    // MARK: Public Initializers

    /// Creates a credit by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted, including a name
    ///             that is empty once its whitespace is normalized.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let name = try container.decode(String.self,
                                        forKey: .name)

        let role = try container.decodeIfPresent(Role.self,
                                                 forKey: .role)

        guard let credit = Self(name: name,
                                role: role)
        else { throw DecodingError.dataCorruptedError(forKey: .name,
                                                      in: container,
                                                      debugDescription: "Empty credit name") }

        self = credit
    }

    // MARK: Public Instance Methods

    /// Encodes this credit into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(name,
                             forKey: .name)

        try container.encodeIfPresent(role,
                                      forKey: .role)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case name
        case role
    }
}

// MARK: - Hashable

extension Credit: Hashable {
}

// MARK: - Sendable

extension Credit: Sendable {
}
