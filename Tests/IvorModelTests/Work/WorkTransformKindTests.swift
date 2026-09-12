// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct WorkTransformKindTests {
}

// MARK: -

extension WorkTransformKindTests {
    @Test
    func description() {
        #expect(Work.TransformKind.augment.description == "augment")
        #expect(Work.TransformKind.diminish.description == "diminish")
        #expect(Work.TransformKind.invert.description == "invert")
        #expect(Work.TransformKind.move.description == "move")
        #expect(Work.TransformKind.quantize.description == "quantize")
        #expect(Work.TransformKind.reverse.description == "reverse")
        #expect(Work.TransformKind.transpose.description == "transpose")
    }

    @Test
    func equality() {
        #expect(Work.TransformKind.augment == .augment)
        #expect(Work.TransformKind.augment != .diminish)
    }
}
