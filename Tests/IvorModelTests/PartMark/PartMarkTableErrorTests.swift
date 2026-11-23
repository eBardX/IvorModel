// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PartMarkTableErrorTests {
}

// MARK: -

extension PartMarkTableErrorTests {
    private typealias Error = PartMarkTable<BeatTime>.Error

    @Test
    func category() {
        #expect(Error.invalidAnchor.category != nil)
    }

    @Test
    func messages() {
        let cases: [(Error, String)] = [(.augmentFailure(1), "augment"),
                                        (.diminishFailure(1), "diminish"),
                                        (.invalidAnchor, "anchor"),
                                        (.invalidAugmentationFactor(frac(1, 2)), "augmentation factor"),
                                        (.invalidDiminutionFactor(frac(1, 2)), "diminution factor"),
                                        (.moveFailure(1), "move"),
                                        (.reverseFailure(1), "reverse")]

        for (error, text) in cases {
            #expect(error.message.contains(text))
        }
    }
}
