// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing

struct DynamicMapEntryIDTests {
}

// MARK: -

extension DynamicMapEntryIDTests {
    private typealias EntryID = DynamicMap<BeatTime>.EntryID

    @Test
    func init_generated() {
        let id1 = EntryID()
        let id2 = EntryID()

        #expect(id1 != id2)
        #expect(id1.stringValue.hasPrefix("E$"))
        #expect(id1.stringValue.count == 24)
    }

    @Test
    func init_invalid() {
        #expect(EntryID(stringValue: "") == nil)
        #expect(EntryID(stringValue: "invalid") == nil)
        #expect(EntryID(stringValue: "N$" + String(repeating: "A", count: 22)) == nil)
        #expect(EntryID(stringValue: "E$" + String(repeating: "A", count: 21)) == nil)
    }

    @Test
    func init_valid() {
        let validString = "E$" + String(repeating: "A", count: 22)

        #expect(EntryID(stringValue: validString) != nil)
    }

    @Test
    func isValid() {
        let validString = "E$" + String(repeating: "A", count: 22)

        #expect(EntryID.isValid(validString))
        #expect(!EntryID.isValid("invalid"))
        #expect(!EntryID.isValid("E$short"))
    }
}
