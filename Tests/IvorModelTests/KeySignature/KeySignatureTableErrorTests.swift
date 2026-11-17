// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct KeySignatureTableErrorTests {
}

// MARK: -

extension KeySignatureTableErrorTests {
    @Test
    func category() {
        #expect(KeySignatureTable.Error.entryExists(0).category != nil)
    }

    @Test
    func equality() {
        #expect(KeySignatureTable.Error.entryExists(1) == .entryExists(1))
        #expect(KeySignatureTable.Error.entryExists(1) != .entryExists(2))
        #expect(KeySignatureTable.Error.invalidAugmentationFactor(0) != .invalidDiminutionFactor(0))
    }

    @Test
    func messages() {
        #expect(KeySignatureTable.Error.entryExists(2).message.contains("already exists"))
        #expect(KeySignatureTable.Error.invalidAugmentationFactor(frac(1, 2)).message.contains("augmentation"))
        #expect(KeySignatureTable.Error.invalidDiminutionFactor(0).message.contains("diminution"))
    }
}
