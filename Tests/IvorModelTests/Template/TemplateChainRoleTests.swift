// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct TemplateChainRoleTests {
}

// MARK: -

extension TemplateChainRoleTests {
    @Test(arguments: [Template.ChainRole.duration, .joint, .pitch])
    func codable(role: Template.ChainRole) throws {
        let data = try JSONEncoder().encode(role)
        let decoded = try JSONDecoder().decode(Template.ChainRole.self,
                                               from: data)

        #expect(decoded == role)
    }

    @Test
    func hashable_casesAreDistinct() {
        let roles: Set<Template.ChainRole> = [.duration, .joint, .pitch, .joint]

        #expect(roles.count == 3)
    }
}
