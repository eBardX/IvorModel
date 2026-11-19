// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct KeyTableErrorTests {
}

// MARK: -

extension KeyTableErrorTests {
    @Test
    func category() {
        #expect(KeyTable.Error.entryExists(0).category != nil)
    }

    @Test
    func equality() {
        #expect(KeyTable.Error.entryExists(1) == .entryExists(1))
        #expect(KeyTable.Error.entryExists(1) != .entryExists(2))
        #expect(KeyTable.Error.invalidAugmentationFactor(0) != .invalidDiminutionFactor(0))
    }

    @Test
    func messages() {
        #expect(KeyTable.Error.entryExists(2).message.contains("already exists"))
        #expect(KeyTable.Error.invalidAugmentationFactor(frac(1, 2)).message.contains("augmentation"))
        #expect(KeyTable.Error.invalidDiminutionFactor(0).message.contains("diminution"))
    }
}
