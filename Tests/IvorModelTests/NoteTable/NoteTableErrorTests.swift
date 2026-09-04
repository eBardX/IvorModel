// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableErrorTests {
}

// MARK: -

extension NoteTableErrorTests {
    private typealias ErrorSB = NoteTable<BeatTime, Pitch>.Error

    @Test
    func category() {
        #expect(ErrorSB.invalidAugmentationFactor(2).category != nil)
    }

    @Test
    func message_augmentFailure_glide() {
        let msg = ErrorSB.augmentFailure(0, 1, .c4, .e4).message

        #expect(msg.contains("startPitch"))
        #expect(msg.contains("endPitch"))
    }

    @Test
    func message_augmentFailure_static() {
        let msg = ErrorSB.augmentFailure(0, 1, .c4, .c4).message

        #expect(msg.contains("pitch"))
        #expect(!msg.contains("startPitch"))
    }

    @Test
    func message_diminishFailure() {
        let msg = ErrorSB.diminishFailure(0, 1, .c4, .c4).message

        #expect(msg.contains("diminish"))
    }

    @Test
    func message_invalidAugmentationFactor() {
        let msg = ErrorSB.invalidAugmentationFactor(Number(0)).message

        #expect(msg.contains("augmentation"))
    }

    @Test
    func message_invalidDiminutionFactor() {
        let msg = ErrorSB.invalidDiminutionFactor(Number(0)).message

        #expect(msg.contains("diminution"))
    }

    @Test
    func message_invalidQuantizationFactor() {
        let msg = ErrorSB.invalidQuantizationFactor(0).message

        #expect(msg.contains("quantization"))
    }

    @Test
    func message_invertFailure() {
        let msg = ErrorSB.invertFailure(0, 1, .c4, .c4).message

        #expect(msg.contains("invert"))
    }

    @Test
    func message_moveFailure() {
        let msg = ErrorSB.moveFailure(0, 1, .c4, .c4).message

        #expect(msg.contains("move"))
    }

    @Test
    func message_reverseFailure() {
        let msg = ErrorSB.reverseFailure(0, 1, .c4, .c4).message

        #expect(msg.contains("reverse"))
    }

    @Test
    func message_transposeFailure() {
        let msg = ErrorSB.transposeFailure(0, 1, .c4, .c4).message

        #expect(msg.contains("transpose"))
    }
}
