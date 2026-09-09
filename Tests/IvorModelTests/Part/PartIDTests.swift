// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct PartIDTests {
}

// MARK: -

extension PartIDTests {
    @Test
    func init_generated() {
        let id1 = PartID()
        let id2 = PartID()

        #expect(id1 != id2)
        #expect(id1.stringValue.hasPrefix("P$"))
        #expect(id1.stringValue.count == 24)
    }

    @Test
    func init_invalid() {
        #expect(PartID(stringValue: "") == nil)
        #expect(PartID(stringValue: "invalid") == nil)
        #expect(PartID(stringValue: "W$" + String(repeating: "A", count: 22)) == nil)
        #expect(PartID(stringValue: "P$" + String(repeating: "A", count: 21)) == nil)
    }

    @Test
    func init_valid() {
        let validString = "P$" + String(repeating: "A", count: 22)

        #expect(PartID(stringValue: validString) != nil)
    }

    @Test
    func isValid() {
        let validString = "P$" + String(repeating: "A", count: 22)

        #expect(PartID.isValid(validString))
        #expect(!PartID.isValid("invalid"))
        #expect(!PartID.isValid("P$short"))
    }
}
