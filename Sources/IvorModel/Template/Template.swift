private import Foundation

public struct Template {

    // MARK: Public Type Properties

    public static let currentVersion = 1

    // MARK: Public Initializers

    public init(name: String,
                content: Content) {
        self.content = content
        self.name = name
        self.templateID = TemplateID()
        self.version = Self.currentVersion
    }

    // MARK: Public Instance Properties

    public let content: Content
    public let name: String
    public let templateID: TemplateID
    public let version: Int
}

// MARK: - Codable

extension Template: Codable {

    // MARK: Public Initializers

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

    public static func < (lhs: Self,
                          rhs: Self) -> Bool {
        (lhs.name, lhs.templateID) < (rhs.name, rhs.templateID)
    }
}

// MARK: - Equatable

extension Template: Equatable {

    // MARK: Public Type Methods

    public static func == (lhs: Self,
                           rhs: Self) -> Bool {
        (lhs.name, lhs.templateID) == (rhs.name, rhs.templateID)
    }
}

// MARK: - Sendable

extension Template: Sendable {
}
