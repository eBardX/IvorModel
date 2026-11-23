// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiNumbers

struct RenderingDefaultsTests {
}

// MARK: -

extension RenderingDefaultsTests {
    @Test
    func appoggiaturaShare() {
        #expect(RenderingDefaults.appoggiaturaShare == proportion(1, 2))
    }

    @Test
    func arpeggioAnchor() {
        #expect(RenderingDefaults.arpeggioAnchor == .firstOnBeat)
    }

    @Test
    func arpeggioDirection() {
        #expect(RenderingDefaults.arpeggioDirection == .up)
    }

    @Test
    func arpeggioMaximumPerTone() {
        #expect(RenderingDefaults.arpeggioMaximumPerTone == positiveSeconds(3, 50))
    }

    @Test
    func caesuraPause() {
        #expect(RenderingDefaults.caesuraPause == positiveSeconds(2))
    }

    @Test
    func compoundAppoggiaturaShare() {
        #expect(RenderingDefaults.compoundAppoggiaturaShare == proportion(2, 3))
    }

    @Test
    func fermataStretches_coverEveryShape() {
        #expect(RenderingDefaults.fermataStretches == [.veryShort: fermataStretch(frac(5, 4)),
                                                       .short: fermataStretch(frac(3, 2)),
                                                       .normal: fermataStretch(2),
                                                       .long: fermataStretch(3),
                                                       .veryLong: fermataStretch(4)])
    }

    @Test
    func graceMaximumShare() {
        #expect(RenderingDefaults.graceMaximumShare == proportion(1, 2))
    }

    @Test
    func gracePerNoteBeat() {
        #expect(RenderingDefaults.gracePerNoteBeat == positiveBeats(1, 64))
    }

    @Test
    func gracePerNoteWall() {
        #expect(RenderingDefaults.gracePerNoteWall == positiveSeconds(1, 25))
    }

    @Test
    func gracePlacement() {
        #expect(RenderingDefaults.gracePlacement == .onBeat)
    }

    @Test
    func mordentMaximumShare() {
        #expect(RenderingDefaults.mordentMaximumShare == proportion(1, 2))
    }

    @Test
    func ornamentRate() {
        #expect(RenderingDefaults.ornamentRate == notesPerSecond(12))
    }

    @Test
    func ornamentStart() {
        #expect(RenderingDefaults.ornamentStart == .main)
    }

    @Test
    func partnerRule() {
        #expect(RenderingDefaults.partnerRule == .diatonic)
    }
}
