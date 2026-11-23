// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct WorkRenderingLeadInTests {
}

// MARK: -

extension WorkRenderingLeadInTests {
    @Test
    func equality() {
        #expect(Work.Rendering.LeadIn.beat(beats(frac(1, 4))) == .beat(beats(frac(1, 4))))
        #expect(Work.Rendering.LeadIn.wall(wallDuration(40)) == .wall(wallDuration(40)))
    }

    @Test
    func inequality_differentKinds() {
        #expect(Work.Rendering.LeadIn.beat(beats(1)) != .wall(wallDuration(1_000)))
    }

    @Test
    func inequality_differentLengths() {
        #expect(Work.Rendering.LeadIn.beat(beats(frac(1, 4))) != .beat(beats(frac(1, 2))))
    }

    @Test
    func rendered_aBeatWorkReportsABeatLeadIn() throws {
        let part = try renderingPart([WrittenNote(0, frac(1, 2), .c4, BeatNotes.Ornamentation(graceBefore: graceFigure([.d4], isSlashed: true)))])
        let rendering = try renderingWork([part],
                                          rules: InterpretationRules(grace: GraceRules(slashedPlacement: .beforeBeat))).rendered()

        guard case .beat? = rendering.leadIn
        else { Issue.record("Expected a beat lead-in"); return }
    }
}
