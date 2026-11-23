// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct RendererGracePlanTests {
}

// MARK: -

extension RendererGracePlanTests {
    @Test
    func init_storesEveryField() {
        let plan = Renderer<BeatTime, Pitch>.GracePlan(inside: frac(1, 64),
                                                       lengths: [frac(1, 64), frac(1, 64)],
                                                       outside: frac(1, 64))

        #expect(plan.inside == frac(1, 64))
        #expect(plan.lengths == [frac(1, 64), frac(1, 64)])
        #expect(plan.outside == frac(1, 64))
    }
}
