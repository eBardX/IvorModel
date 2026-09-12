// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct WorkIDTests {
}

// MARK: -

extension WorkIDTests {
    @Test
    func init_generated() {
        let id1 = WorkID()
        let id2 = WorkID()

        #expect(id1 != id2)
        #expect(id1.stringValue.hasPrefix("W$"))
        #expect(id1.stringValue.count == 24)
    }

    @Test
    func init_invalid() {
        #expect(WorkID(stringValue: "") == nil)
        #expect(WorkID(stringValue: "invalid") == nil)
        #expect(WorkID(stringValue: "T$" + String(repeating: "A", count: 22)) == nil)
        #expect(WorkID(stringValue: "W$" + String(repeating: "A", count: 21)) == nil)
    }

    @Test
    func init_valid() {
        let validString = "W$" + String(repeating: "A", count: 22)

        #expect(WorkID(stringValue: validString) != nil)
    }

    @Test
    func isValid() {
        let validString = "W$" + String(repeating: "A", count: 22)

        #expect(WorkID.isValid(validString))
        #expect(!WorkID.isValid("invalid"))
        #expect(!WorkID.isValid("W$short"))
    }
}
