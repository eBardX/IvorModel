// © 2025–2026 John Gary Pusey (see LICENSE.md)

extension Project {

    // MARK: Internal Nested Types

    internal struct Manifest {

        // MARK: Internal Type Properties

        internal static let currentVersion = 1

        // MARK: Internal Initializers

        internal init(name: String,
                      workIDs: [WorkID],
                      templateIDs: [TemplateID]) {
            self.name = name
            self.templateIDs = templateIDs
            self.version = Self.currentVersion
            self.workIDs = workIDs
        }

        // MARK: Internal Instance Properties

        internal let name: String
        internal let templateIDs: [TemplateID]
        internal let version: Int
        internal let workIDs: [WorkID]
    }
}

// MARK: - Codable

extension Project.Manifest: Codable {

    // MARK: Internal Initializers

    internal init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.name = try container.decode(String.self,
                                         forKey: .name)

        self.templateIDs = try container.decode([TemplateID].self,
                                                forKey: .templateIDs)

        self.version = try container.decode(Int.self,
                                            forKey: .version)

        self.workIDs = try container.decode([WorkID].self,
                                            forKey: .workIDs)

        guard version == Self.currentVersion
        else { throw Project.Error.unsupportedVersion(version) }
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(version,
                             forKey: .version)

        try container.encode(name,
                             forKey: .name)

        try container.encode(workIDs,
                             forKey: .workIDs)

        try container.encode(templateIDs,
                             forKey: .templateIDs)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case name
        case templateIDs
        case version
        case workIDs
    }
}

// MARK: - Sendable

extension Project.Manifest: Sendable {
}
