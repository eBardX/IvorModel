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
    func message_invalidKeyboardLayout() {
        let msg = Work.Error.invalidKeyboardLayout(.slotOutsidePeriod(index: 2)).message

        #expect(msg == TuningError.invalidKeyboardLayout(.slotOutsidePeriod(index: 2)).message)
        #expect(msg.contains("2"))
    }

    @Test
    func message_meterTableTransformFailure() {
        let msg = Work.Error.meterTableTransformFailure(kind: .augment,
                                                        detail: "boom").message

        #expect(msg.contains("Meter table"))
        #expect(msg.contains("boom"))
    }

    @Test
    func message_missingKeyboardLayout() {
        #expect(!Work.Error.missingKeyboardLayout.message.isEmpty)
    }

    @Test
    func message_noRealizations() {
        #expect(!Work.Error.noRealizations.message.isEmpty)
    }

    @Test
    func message_pedalTableTransformFailure() {
        let msg = Work.Error.pedalTableTransformFailure(kind: .augment,
                                                        partID: PartID(),
                                                        pedal: .sustain,
                                                        detail: "boom").message

        #expect(msg.contains("Pedal table"))
        #expect(msg.contains("sustain"))
        #expect(msg.contains("boom"))
    }

    @Test
    func message_unconvertiblePitch() {
        let partID = PartID()
        let msg = Work.Error.unconvertiblePitch(partID: partID).message

        #expect(msg.contains(partID.stringValue))
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
