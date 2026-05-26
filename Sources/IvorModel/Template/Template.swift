// © 2025–2026 John Gary Pusey (see LICENSE.md)

private import Foundation

/// An analysis of a ``Work`` that captures its musical essence and can generate new, derived works.
public struct Template {

    // MARK: Public Type Properties

    /// The current template file format version.
    public static let currentVersion = 1

    // MARK: Public Initializers

    /// Creates a new template with the given name and content.
    ///
    /// - Parameter name:     The display name of the template.
    /// - Parameter content:  The ``Template/Content`` holding the analysis data.
    public init(name: String,
                content: Content) {
        self.content = content
        self.name = name
        self.templateID = TemplateID()
        self.version = Self.currentVersion
    }

    // MARK: Public Instance Properties

    /// The analysis data stored in this template.
    public let content: Content

    /// The display name of this template.
    public let name: String

    /// The unique ID of this template.
    public let templateID: TemplateID

    /// The file format version of this template.
    public let version: Int
}

// MARK: - Codable

extension Template: Codable {

    // MARK: Public Initializers

    /// Creates a template by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted;
    ///             otherwise, ``Template/Error/unsupportedVersion(_:)`` if the version is
    ///             not supported.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.content = try container.decode(Content.self,
                                            forKey: .content)

        self.name = try container.decode(String.self,
                                         forKey: .name)

        self.templateID = try container.decode(TemplateID.self,
                                               forKey: .templateID)

        self.version = try container.decode(Int.self,
                                            forKey: .version)

        guard version == Self.currentVersion
        else { throw Error.unsupportedVersion(version) }
    }

    // MARK: Public Instance Methods

    /// Encodes this template into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(templateID,
                             forKey: .templateID)

        try container.encode(name,
                             forKey: .name)

        try container.encode(version,
                             forKey: .version)

        try container.encode(content,
                             forKey: .content)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case content
        case name
        case templateID
        case version
    }
}

// MARK: - Comparable

extension Template: Comparable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the left template compares less than the right.
    ///
    /// - Parameter lhs:    The left-hand template.
    /// - Parameter rhs:    The right-hand template.
    ///
    /// - Returns:  `true` if `lhs` precedes `rhs` when ordered by name then template ID.
    public static func < (lhs: Self,
                          rhs: Self) -> Bool {
        (lhs.name, lhs.templateID) < (rhs.name, rhs.templateID)
    }
}

// MARK: - Equatable

extension Template: Equatable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether two templates are equal.
    ///
    /// - Parameter lhs:    The left-hand template.
    /// - Parameter rhs:    The right-hand template.
    ///
    /// - Returns:  `true` if both templates have the same name and template ID.
    public static func == (lhs: Self,
                           rhs: Self) -> Bool {
        (lhs.name, lhs.templateID) == (rhs.name, rhs.templateID)
    }
}

// MARK: - Sendable

extension Template: Sendable {
}
