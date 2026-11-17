// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiNumbers

struct KeySignatureTableIndexTests {
}

// MARK: -

extension KeySignatureTableIndexTests {
    @Test
    func collection_indices() throws {
        let table = try makeKeySignatureTable([(0, 2), (4, -1), (8, 0)])
        let second = table.index(after: table.startIndex)

        #expect(table.distance(from: table.startIndex, to: table.endIndex) == 3)
        #expect(table[second].keySignature == keySignature(-1))
        #expect(table.index(before: second) == table.startIndex)
        #expect(table.index(table.startIndex, offsetBy: 2) < table.endIndex)
    }

    @Test
    func comparable() {
        #expect(KeySignatureTable.Index(0) < KeySignatureTable.Index(1))
        #expect(KeySignatureTable.Index(1) == KeySignatureTable.Index(1))   // swiftlint:disable:this identical_operands
    }
}
