// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct StrandIDTests {
}

// MARK: -

extension StrandIDTests {
    @Test
    func init_generated() {
        let id1 = StrandID()
        let id2 = StrandID()

        #expect(id1 != id2)
        #expect(id1.stringValue.hasPrefix("S$"))
        #expect(id1.stringValue.count == 24)
    }

    @Test
    func init_invalid() {
        #expect(StrandID(stringValue: "") == nil)
        #expect(StrandID(stringValue: "invalid") == nil)
        #expect(StrandID(stringValue: "P$" + String(repeating: "A", count: 22)) == nil)
        #expect(StrandID(stringValue: "S$" + String(repeating: "A", count: 21)) == nil)
    }

    @Test
    func init_valid() {
        let validString = "S$" + String(repeating: "A", count: 22)

        #expect(StrandID(stringValue: validString) != nil)
    }

    @Test
    func isValid() {
        let validString = "S$" + String(repeating: "A", count: 22)

        #expect(StrandID.isValid(validString))
        #expect(!StrandID.isValid("invalid"))
        #expect(!StrandID.isValid("S$short"))
    }
}
