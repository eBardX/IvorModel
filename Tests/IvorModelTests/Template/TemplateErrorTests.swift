// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct TemplateErrorTests {
}

// MARK: -

extension TemplateErrorTests {
    @Test
    func category() {
        #expect(Template.Error.invalidLimit.category != nil)
    }

    @Test
    func message_invalidLimit() {
        let msg = Template.Error.invalidLimit.message

        #expect(!msg.isEmpty)
    }

    @Test
    func message_invalidMaximumOrder() {
        let msg = Template.Error.invalidMaximumOrder.message

        #expect(!msg.isEmpty)
    }

    @Test
    func message_invalidOrder() {
        let msg = Template.Error.invalidOrder(5).message

        #expect(msg.contains("5"))
    }

    @Test
    func message_invalidTolerance() {
        #expect(Template.Error.invalidTolerance.message == "Tolerance must be positive (> 0)")
    }

    @Test
    func message_notFound() {
        let noteID = NoteID()
        let partID = PartID()
        let strandID = StrandID()

        #expect(Template.Error.noteNotFound(noteID).message.contains(noteID.stringValue))
        #expect(Template.Error.partNotFound(partID).message.contains(partID.stringValue))
        #expect(Template.Error.strandNotFound(strandID).message.contains(strandID.stringValue))
    }

    @Test
    func message_source() {
        #expect(!Template.Error.sourceIsEmpty.message.isEmpty)
        #expect(!Template.Error.sourceSpansParts.message.isEmpty)
    }

    @Test
    func message_templateIsLocked() {
        #expect(!Template.Error.templateIsLocked.message.isEmpty)
    }

    @Test
    func message_unsupportedVersion() {
        let msg = Template.Error.unsupportedVersion(99).message

        #expect(msg.contains("99"))
    }
}
