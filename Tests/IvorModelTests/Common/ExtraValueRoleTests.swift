// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiTools

struct ExtraValueRoleTests {
}

// MARK: -

extension ExtraValueRoleTests {
    @Test
    func allCases_count() {
        #expect(Extra.ValueRole.allCases.count == 23)
    }

    @Test
    func allCases_eachUsedByADefinition() {
        let used = Set(Extra.definitions.flatMap { $0.values.map(\.role) })

        #expect(used == Set(Extra.ValueRole.allCases))
    }

    @Test
    func hashable() {
        #expect(Set(Extra.ValueRole.allCases).count == Extra.ValueRole.allCases.count)
    }
}
