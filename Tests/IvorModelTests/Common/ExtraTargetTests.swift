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
                                          .keySignatureEntry,
                                          .meterEntry,
                                          .note,
                                          .panEntry,
                                          .part,
                                          .pedalEntry,
                                          .tempoEntry,
                                          .work])
    }

    @Test
    func allCases_eachTargetedByADefinitionExceptPedalEntry() {
        let targeted = Set(Extra.definitions.flatMap(\.targets))

        #expect(targeted == Set(Extra.Target.allCases).subtracting([.pedalEntry]))
    }

    @Test
    func hashable() {
        #expect(Set(Extra.Target.allCases).count == Extra.Target.allCases.count)
    }
}
