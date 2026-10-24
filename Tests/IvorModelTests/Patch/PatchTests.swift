// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct PatchTests {
}

// MARK: -

extension PatchTests {
    @Test
    func codable_rejectsOutOfRangeProgram() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Patch.self, from: Data(#"{"generalMIDI1":{"program":0}}"#.utf8))
        }
    }

    @Test(arguments: [Patch.Kind.custom(program: 5, bankMSB: 1, bankLSB: nil, name: "Warm Pad"),
                      .generalMIDI1(program: 41),
                      .generalMIDI1Percussion,
                      .generalMIDI2(program: 20, variation: 2),
                      .generalMIDI2DrumSet(program: 9)])
    func codable_roundTrip(kind: Patch.Kind) throws {
        let original = try #require(Patch(kind))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Patch.self, from: data)

        #expect(decoded == original)
    }

    @Test
    func init_normalizesCustomName() throws {
        let blank = try #require(Patch(.custom(program: 1, bankMSB: nil, bankLSB: nil, name: "  ")))
        let spaced = try #require(Patch(.custom(program: 1, bankMSB: nil, bankLSB: nil, name: " Warm\n Pad ")))

        #expect(blank.kind == .custom(program: 1, bankMSB: nil, bankLSB: nil, name: nil))
        #expect(spaced.kind == .custom(program: 1, bankMSB: nil, bankLSB: nil, name: "Warm Pad"))
    }

    @Test(arguments: [Patch.Kind.custom(program: 129, bankMSB: nil, bankLSB: nil, name: nil),
                      .custom(program: 1, bankMSB: 128, bankLSB: nil, name: nil),
                      .custom(program: 1, bankMSB: nil, bankLSB: -1, name: nil),
                      .generalMIDI1(program: 0),
                      .generalMIDI2(program: 1, variation: 128),
                      .generalMIDI2DrumSet(program: 129)])
    func init_rejectsOutOfRangeNumbers(kind: Patch.Kind) {
        #expect(Patch(kind) == nil)
    }

    @Test
    func isPercussion() throws {
        #expect(try #require(Patch(.generalMIDI1Percussion)).isPercussion)
        #expect(try #require(Patch(.generalMIDI2DrumSet(program: 1))).isPercussion)
        #expect(try !#require(Patch(.generalMIDI1(program: 1))).isPercussion)
        #expect(try !#require(Patch(.generalMIDI2(program: 1, variation: 0))).isPercussion)
        #expect(try !#require(Patch(.custom(program: 1, bankMSB: nil, bankLSB: nil, name: nil))).isPercussion)
    }
}
