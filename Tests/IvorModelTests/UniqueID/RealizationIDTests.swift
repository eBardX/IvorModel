// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct RealizationIDTests {
}

// MARK: -

extension RealizationIDTests {
    @Test
    func init_generated() {
        let id1 = RealizationID()
        let id2 = RealizationID()

        #expect(id1 != id2)
        #expect(id1.stringValue.hasPrefix("R$"))
        #expect(id1.stringValue.count == 24)
    }

    @Test
    func init_invalid() {
        #expect(RealizationID(stringValue: "") == nil)
        #expect(RealizationID(stringValue: "invalid") == nil)
        #expect(RealizationID(stringValue: "T$" + String(repeating: "A", count: 22)) == nil)
        #expect(RealizationID(stringValue: "R$" + String(repeating: "A", count: 21)) == nil)
    }

    @Test
    func init_valid() {
        let validString = "R$" + String(repeating: "A", count: 22)

        #expect(RealizationID(stringValue: validString) != nil)
    }

    @Test
    func isValid() {
        let validString = "R$" + String(repeating: "A", count: 22)

        #expect(RealizationID.isValid(validString))
        #expect(!RealizationID.isValid("invalid"))
        #expect(!RealizationID.isValid("R$short"))
    }
}
