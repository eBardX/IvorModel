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
    func message_partNotFound() {
        let msg = Template.Error.partNotFound(3).message

        #expect(msg.contains("3"))
    }

    @Test
    func message_unsupportedVersion() {
        let msg = Template.Error.unsupportedVersion(99).message

        #expect(msg.contains("99"))
    }
}
