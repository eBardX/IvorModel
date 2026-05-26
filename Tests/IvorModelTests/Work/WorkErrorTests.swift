// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct WorkErrorTests {
}

// MARK: -

extension WorkErrorTests {
    @Test
    func category() {
        #expect(Work.Error.unsupportedVersion(1).category != nil)
    }

    @Test
    func message_unsupportedVersion() {
        let msg = Work.Error.unsupportedVersion(42).message

        #expect(msg.contains("42"))
    }
}
