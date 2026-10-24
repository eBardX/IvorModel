// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTuning
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
    func message_duplicatePartID() {
        #expect(!Work.Error.duplicatePartID(PartID()).message.isEmpty)
    }

    @Test
    func message_duplicateRealizationID() {
        #expect(!Work.Error.duplicateRealizationID(RealizationID()).message.isEmpty)
    }

    @Test
    func message_noRealizations() {
        #expect(!Work.Error.noRealizations.message.isEmpty)
    }

    @Test
    func message_unsupportedPitchConversion() {
        let msg = Work.Error.unsupportedPitchConversion(from: .keyboard,
                                                        to: .standard).message

        #expect(msg.contains("keyboard"))
        #expect(msg.contains("standard"))
    }

    @Test
    func message_unsupportedVersion() {
        let msg = Work.Error.unsupportedVersion(42).message

        #expect(msg.contains("42"))
    }

    @Test
    func message_workIsLocked() {
        #expect(!Work.Error.workIsLocked.message.isEmpty)
    }
}
