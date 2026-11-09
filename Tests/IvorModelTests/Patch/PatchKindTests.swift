// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct PatchKindTests {
}

// MARK: -

extension PatchKindTests {
    @Test(arguments: [Patch.Kind.custom(program: 5, bank: 300, name: "Pad"),
                      .custom(program: 5, bank: nil, name: nil),
                      .generalMIDI1(program: 1),
                      .generalMIDI1Percussion,
                      .generalMIDI2(program: 1, variation: 2),
                      .generalMIDI2DrumSet(program: 26)])
    func codable(kind: Patch.Kind) throws {
        let data = try JSONEncoder().encode(kind)
        let decoded = try JSONDecoder().decode(Patch.Kind.self,
                                               from: data)

        #expect(decoded == kind)
    }

    @Test
    func equality() {
        #expect(Patch.Kind.custom(program: 5, bank: 1, name: "A") == .custom(program: 5, bank: 1, name: "A"))
        #expect(Patch.Kind.generalMIDI2(program: 1, variation: 2) == .generalMIDI2(program: 1, variation: 2))
    }

    @Test
    func hashable_casesAreDistinct() {
        let kinds: Set<Patch.Kind> = [.custom(program: 1, bank: nil, name: nil),
                                      .generalMIDI1(program: 1),
                                      .generalMIDI1Percussion,
                                      .generalMIDI2(program: 1, variation: 0),
                                      .generalMIDI2DrumSet(program: 1),
                                      .generalMIDI1(program: 1)]

        #expect(kinds.count == 5)
    }

    @Test
    func inequality_differentAssociatedValues() {
        #expect(Patch.Kind.custom(program: 5, bank: 1, name: "A") != .custom(program: 5, bank: 1, name: "B"))
        #expect(Patch.Kind.generalMIDI1(program: 1) != .generalMIDI1(program: 2))
        #expect(Patch.Kind.generalMIDI2(program: 1, variation: 2) != .generalMIDI2(program: 1, variation: 3))
    }
}
