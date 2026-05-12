private import Foundation

public struct Work {

    // MARK: Public Type Properties

    public static let currentVersion = 1

    // MARK: Public Initializers

    public init(name: String = "",
                content: Content? = nil) {
        self.content = content ?? .standardBeat([],
                                                TempoMap())
        self.name = name
        self.workID = WorkID()
        self.version = Self.currentVersion
    }

    // MARK: Public Instance Properties

    public let version: Int
    public let workID: WorkID

    public var content: Content
    public var name: String
}

// MARK: - Codable

extension Work: Codable {

    // MARK: Public Initializers

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.content = try container.decode(Content.self,
                                            forKey: .content)

        self.name = try container.decode(String.self,
                                         forKey: .name)

        self.version = try container.decode(Int.self,
                                            forKey: .version)

        guard version == Self.currentVersion
        else { throw Error.unsupportedVersion(version) }

        self.workID = try container.decode(WorkID.self,
                                           forKey: .workID)
    }

    // MARK: Public Instance Methods

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(workID,
                             forKey: .workID)

        try container.encode(version,
                             forKey: .version)

        try container.encode(name,
                             forKey: .name)

        try container.encode(content,
                             forKey: .content)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case content
        case name
        case version
        case workID
    }
}

// MARK: - Comparable

extension Work: Comparable {

    // MARK: Public Type Methods

    public static func < (lhs: Self,
                          rhs: Self) -> Bool {
        (lhs.name, lhs.workID) < (rhs.name, rhs.workID)
    }
}

// MARK: - Equatable

extension Work: Equatable {

    // MARK: Public Type Methods

    public static func == (lhs: Self,
                           rhs: Self) -> Bool {
        (lhs.name, lhs.workID) == (rhs.name, rhs.workID)
    }
}

// MARK: - Sendable

extension Work: Sendable {
}
