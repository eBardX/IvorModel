// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct RendererRollKeyTests {
}

// MARK: -

extension RendererRollKeyTests {
    private typealias RollKey = Renderer<BeatTime, Pitch>.RollKey

    @Test
    func equality() {
        #expect(RollKey(group: 1, part: 0, time: 0) == RollKey(group: 1, part: 0, time: 0)) // swiftlint:disable:this identical_operands
    }

    @Test
    func hashable() {
        let keys: Set = [RollKey(group: 1, part: 0, time: 0),
                         RollKey(group: 1, part: 0, time: 0),
                         RollKey(group: 2, part: 0, time: 0),
                         RollKey(group: 1, part: 0, time: 1)]

        #expect(keys.count == 3)
    }

    @Test
    func inequality_differentGroup() {
        #expect(RollKey(group: 1, part: 0, time: 0) != RollKey(group: 2, part: 0, time: 0))
    }

    @Test
    func inequality_differentPart() {
        #expect(RollKey(group: 1, part: 0, time: 0) != RollKey(group: 1, part: 1, time: 0))
    }

    @Test
    func inequality_differentTime() {
        #expect(RollKey(group: 1, part: 0, time: 0) != RollKey(group: 1, part: 0, time: frac(1, 2)))
    }
}
