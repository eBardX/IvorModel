// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct TimelineOperationTests {
}

// MARK: -

extension TimelineOperationTests {
    @Test
    func mapped_insertKeepsAReleaseAtItsMoment() {
        #expect(TimelineOperation.insert(at: 1, length: frac(1, 2)).mapped(1, isRelease: true) == 1)
    }

    @Test
    func mapped_insertKeepsEarlierPositions() {
        #expect(TimelineOperation.insert(at: 1, length: frac(1, 2)).mapped(frac(1, 2)) == frac(1, 2))
    }

    @Test
    func mapped_insertMovesAnAttackAtItsMomentLater() {
        #expect(TimelineOperation.insert(at: 1, length: frac(1, 2)).mapped(1) == frac(3, 2))
    }

    @Test
    func mapped_insertMovesLaterPositions() {
        #expect(TimelineOperation.insert(at: 1, length: frac(1, 2)).mapped(2, isRelease: true) == frac(5, 2))
    }

    @Test
    func mapped_stretchKeepsPositionsUpToItsStart() {
        let stretch = TimelineOperation.stretch(from: 1, to: 2, extra: 1)

        #expect(stretch.mapped(frac(1, 2)) == frac(1, 2))
        #expect(stretch.mapped(1) == 1)
    }

    @Test
    func mapped_stretchMovesLaterPositionsByItsExtra() {
        #expect(TimelineOperation.stretch(from: 1, to: 2, extra: 1).mapped(3) == 4)
    }

    @Test
    func mapped_stretchSpreadsPositionsInside() {
        let stretch = TimelineOperation.stretch(from: 1, to: 2, extra: 1)

        #expect(stretch.mapped(frac(3, 2)) == 2)
        #expect(stretch.mapped(2) == 3)
    }

    @Test
    func time() {
        #expect(TimelineOperation.insert(at: 2, length: 1).time == 2)
        #expect(TimelineOperation.stretch(from: 3, to: 4, extra: 1).time == 3)
    }
}
