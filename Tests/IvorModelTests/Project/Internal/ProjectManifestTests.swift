// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct ProjectManifestTests {
}

// MARK: -

extension ProjectManifestTests {
    @Test
    func codable() throws {
        let workID = WorkID()
        let templateID = TemplateID()
        let original = Project.Manifest(name: "My Project",
                                        workIDs: [workID],
                                        templateIDs: [templateID])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Project.Manifest.self,
                                               from: data)

        #expect(decoded.name == original.name)
        #expect(decoded.templateIDs == original.templateIDs)
        #expect(decoded.version == original.version)
        #expect(decoded.workIDs == original.workIDs)
    }

    @Test
    func codable_unsupportedVersion() throws {
        let json = """
            {
              "name": "My Project",
              "templateIDs": [],
              "version": 999,
              "workIDs": []
            }
            """
        let data = Data(json.utf8)

        #expect(throws: Project.Error.self) {
            try JSONDecoder().decode(Project.Manifest.self,
                                     from: data)
        }
    }

    @Test
    func currentVersion() {
        #expect(Project.Manifest.currentVersion == 1)
    }

    @Test
    func init_properties() {
        let workID = WorkID()
        let templateID = TemplateID()
        let manifest = Project.Manifest(name: "My Project",
                                        workIDs: [workID],
                                        templateIDs: [templateID])

        #expect(manifest.name == "My Project")
        #expect(manifest.templateIDs == [templateID])
        #expect(manifest.version == Project.Manifest.currentVersion)
        #expect(manifest.workIDs == [workID])
    }
}
