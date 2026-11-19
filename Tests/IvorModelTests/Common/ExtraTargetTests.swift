// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiTools

struct ExtraTargetTests {
}

// MARK: -

extension ExtraTargetTests {
    @Test
    func allCases() {
        #expect(Extra.Target.allCases == [.dynamicEntry,
                                          .instrumentEntry,
                                          .keyEntry,
                                          .meterEntry,
                                          .note,
                                          .panEntry,
                                          .part,
                                          .pedalEntry,
                                          .tempoEntry,
                                          .work])
    }

    @Test
    func allCases_eachTargetedByADefinitionExceptKeyAndPedalEntries() {
        let targeted = Set(Extra.definitions.flatMap(\.targets))

        #expect(targeted == Set(Extra.Target.allCases).subtracting([.keyEntry, .pedalEntry]))
    }

    @Test
    func hashable() {
        #expect(Set(Extra.Target.allCases).count == Extra.Target.allCases.count)
    }
}
