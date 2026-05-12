@testable import IvorModel
import Testing

struct TemplateIDTests {
}

// MARK: -

extension TemplateIDTests {
    @Test
    func init_generated() {
        let id1 = TemplateID()
        let id2 = TemplateID()

        #expect(id1 != id2)
        #expect(id1.stringValue.hasPrefix("T$"))
        #expect(id1.stringValue.count == 24)
    }

    @Test
    func init_invalid() {
        #expect(TemplateID(stringValue: "") == nil)
        #expect(TemplateID(stringValue: "invalid") == nil)
        #expect(TemplateID(stringValue: "W$" + String(repeating: "A", count: 22)) == nil)
        #expect(TemplateID(stringValue: "T$" + String(repeating: "A", count: 21)) == nil)
    }

    @Test
    func init_valid() {
        let validString = "T$" + String(repeating: "A", count: 22)

        #expect(TemplateID(stringValue: validString) != nil)
    }

    @Test
    func isValid() {
        let validString = "T$" + String(repeating: "A", count: 22)

        #expect(TemplateID.isValid(validString))
        #expect(!TemplateID.isValid("invalid"))
        #expect(!TemplateID.isValid("T$short"))
    }
}
