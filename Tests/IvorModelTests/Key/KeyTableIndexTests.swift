// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiNumbers

struct KeyTableIndexTests {
}

// MARK: -

extension KeyTableIndexTests {
    @Test
    func collection_indices() throws {
        let table = try makeKeyTable([(0, 2), (4, -1), (8, 0)])
        let second = table.index(after: table.startIndex)

        #expect(table.distance(from: table.startIndex, to: table.endIndex) == 3)
        #expect(table[second].key == key(-1))
        #expect(table.index(before: second) == table.startIndex)
        #expect(table.index(table.startIndex, offsetBy: 2) < table.endIndex)
    }

    @Test
    func comparable() {
        #expect(KeyTable.Index(0) < KeyTable.Index(1))
        #expect(KeyTable.Index(1) == KeyTable.Index(1))   // swiftlint:disable:this identical_operands
    }
}
