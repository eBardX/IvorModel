// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct ProjectErrorTests {
}

// MARK: -

extension ProjectErrorTests {
    @Test
    func category() {
        #expect(Project.Error.corruptedProject.category != nil)
    }

    @Test
    func cause_corruptedProject() {
        #expect(Project.Error.corruptedProject.cause == nil)
    }

    @Test
    func cause_loadFailure_nil() {
        #expect(Project.Error.loadFailure(nil).cause == nil)
    }

    @Test
    func cause_loadFailure_withError() {
        let inner = Project.Error.corruptedProject
        let error = Project.Error.loadFailure(inner)

        #expect(error.cause != nil)
    }

    @Test
    func cause_saveFailure_nil() {
        #expect(Project.Error.saveFailure(nil).cause == nil)
    }

    @Test
    func cause_saveFailure_withError() {
        let inner = Project.Error.corruptedProject
        let error = Project.Error.saveFailure(inner)

        #expect(error.cause != nil)
    }

    @Test
    func cause_unsupportedVersion() {
        #expect(Project.Error.unsupportedVersion(99).cause == nil)
    }

    @Test
    func message_corruptedProject() {
        let msg = Project.Error.corruptedProject.message

        #expect(!msg.isEmpty)
    }

    @Test
    func message_loadFailure() {
        let msg = Project.Error.loadFailure(nil).message

        #expect(!msg.isEmpty)
    }

    @Test
    func message_saveFailure() {
        let msg = Project.Error.saveFailure(nil).message

        #expect(!msg.isEmpty)
    }

    @Test
    func message_unsupportedVersion() {
        let msg = Project.Error.unsupportedVersion(42).message

        #expect(msg.contains("42"))
    }
}
