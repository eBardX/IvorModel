// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct RendererMomentTests {
}

// MARK: -

extension RendererMomentTests {
    private typealias Moment = Renderer<BeatTime, Pitch>.Moment

    @Test
    func equality() {
        #expect(Moment(part: 1, time: frac(1, 2)) == Moment(part: 1, time: frac(1, 2))) // swiftlint:disable:this identical_operands
    }

    @Test
    func hashable() {
        let moments: Set = [Moment(part: 0, time: 1),
                            Moment(part: 0, time: 1),
                            Moment(part: 1, time: 1),
                            Moment(part: 0, time: 2)]

        #expect(moments.count == 3)
    }

    @Test
    func inequality_differentPart() {
        #expect(Moment(part: 0, time: 1) != Moment(part: 1, time: 1))
    }

    @Test
    func inequality_differentTime() {
        #expect(Moment(part: 0, time: 1) != Moment(part: 0, time: 2))
    }
}
