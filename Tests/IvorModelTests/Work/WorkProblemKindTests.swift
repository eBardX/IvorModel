// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct WorkProblemKindTests {
}

// MARK: -

extension WorkProblemKindTests {
    @Test
    func allCasesAreDistinct() {
        let kinds: Set<Work.Problem.Kind> = [.ambiguousHoldSpan,
                                             .conflictingArpeggio,
                                             .conflictingDefaultHolds,
                                             .conflictingExplicitHolds,
                                             .unorderedGraceAmounts]

        #expect(kinds.count == 5)
    }

    @Test
    func equality() {
        #expect(Work.Problem.Kind.conflictingArpeggio == .conflictingArpeggio)
    }

    @Test
    func inequality() {
        #expect(Work.Problem.Kind.conflictingDefaultHolds != .conflictingExplicitHolds)
    }
}
