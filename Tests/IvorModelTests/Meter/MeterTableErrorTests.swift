// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct MeterTableErrorTests {
}

// MARK: -

extension MeterTableErrorTests {
    @Test
    func category() {
        #expect(MeterTable.Error.invalidPickup.category != nil)
    }

    @Test
    func equality() {
        #expect(MeterTable.Error.entryExists(1) == .entryExists(1))
    }

    @Test
    func inequality() {
        #expect(MeterTable.Error.entryExists(1) != .entryExists(2))
        #expect(MeterTable.Error.invalidAugmentationFactor(0) != .invalidDiminutionFactor(0))
    }

    @Test
    func message_entryExists() {
        let msg = MeterTable.Error.entryExists(1).message

        #expect(msg.contains("already exists"))
    }

    @Test
    func message_invalidAugmentationFactor() {
        let msg = MeterTable.Error.invalidAugmentationFactor(Number(0)).message

        #expect(msg.contains("augmentation"))
    }

    @Test
    func message_invalidDiminutionFactor() {
        let msg = MeterTable.Error.invalidDiminutionFactor(Number(0)).message

        #expect(msg.contains("diminution"))
    }

    @Test
    func message_invalidPickup() {
        let msg = MeterTable.Error.invalidPickup.message

        #expect(msg.contains("pickup"))
    }
}
