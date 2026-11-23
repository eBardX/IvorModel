// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct WorkRenderingTests {
}

// MARK: -

extension WorkRenderingTests {
    @Test
    func init_storesEveryField() {
        let work = Work(name: "Rendered")
        let rendering = Work.Rendering(work: work,
                                       leadIn: .beat(beats(frac(1, 4))),
                                       fermataTimes: [.beat(beatTime(1)), .beat(beatTime(2))])

        #expect(rendering.fermataTimes == [.beat(beatTime(1)), .beat(beatTime(2))])
        #expect(rendering.leadIn == .beat(beats(frac(1, 4))))
        #expect(rendering.work == work)
    }

    @Test
    func init_withoutALeadIn() {
        let rendering = Work.Rendering(work: Work(name: "Plain"),
                                       leadIn: nil,
                                       fermataTimes: [])

        #expect(rendering.fermataTimes.isEmpty)
        #expect(rendering.leadIn == nil)
    }

    @Test
    func rendered_aPlainWorkHasNoLeadInOrFermataTimes() throws {
        let rendering = try renderingWork([renderingPart([WrittenNote(0, 1, .c4)])]).rendered()

        #expect(rendering.fermataTimes.isEmpty)
        #expect(rendering.leadIn == nil)
    }
}
