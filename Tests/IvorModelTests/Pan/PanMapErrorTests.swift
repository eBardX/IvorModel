// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PanMapErrorTests {
}

// MARK: -

extension PanMapErrorTests {
    private typealias ErrorSB = PanMap<BeatTime>.Error

    @Test
    func category() {
        #expect(ErrorSB.invalidAugmentationFactor(2).category != nil)
    }

    @Test
    func message_augmentFailure() {
        let msg = ErrorSB.augmentFailure(0).message

        #expect(msg.contains("augment"))
    }

    @Test
    func message_diminishFailure() {
        let msg = ErrorSB.diminishFailure(0).message

        #expect(msg.contains("diminish"))
    }

    @Test
    func message_invalidAnchor() {
        let msg = ErrorSB.invalidAnchor.message

        #expect(msg.contains("anchor"))
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
    func message_moveFailure() {
        let msg = ErrorSB.moveFailure(0).message

        #expect(msg.contains("move"))
    }

    @Test
    func message_reverseFailure() {
        let msg = ErrorSB.reverseFailure(0).message

        #expect(msg.contains("reverse"))
    }
}
