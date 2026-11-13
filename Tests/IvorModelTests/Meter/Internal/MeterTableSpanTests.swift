// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct MeterTableSpanTests {
    //
    // Three bars of 3/4 from 0, cut off at 2, so the last bar is short.
    //
    private let closed = MeterTable.Span(barCount: 3,
                                         end: 2,
                                         entryIndex: 0,
                                         firstBarNumber: 1,
                                         meter: meter("3/4"),
                                         start: 0)

    private let free = MeterTable.Span(barCount: 1,
                                       end: 3,
                                       entryIndex: 1,
                                       firstBarNumber: 4,
                                       meter: .free,
                                       start: 2)

    private let open = MeterTable.Span(barCount: nil,
                                       end: nil,
                                       entryIndex: 2,
                                       firstBarNumber: 5,
                                       meter: meter("4/4"),
                                       start: 3)
}

// MARK: -

extension MeterTableSpanTests {
    @Test
    func barEnd() {
        #expect(closed.barEnd(1) == beatTime(frac(3, 4)))
        #expect(closed.barEnd(2) == beatTime(frac(3, 2)))
        #expect(open.barEnd(6) == 5)
    }

    @Test
    func barEnd_cutOffAtSpanEnd() {
        #expect(closed.barEnd(3) == 2)
    }

    @Test
    func barEnd_freeSpan_isSpanEnd() {
        #expect(free.barEnd(4) == 3)
        #expect(MeterTable.Span(barCount: nil,
                                end: nil,
                                entryIndex: 0,
                                firstBarNumber: 1,
                                meter: .free,
                                start: 0).barEnd(1) == nil)
    }

    @Test
    func barNumber_containing() {
        #expect(closed.barNumber(containing: 0) == 1)
        #expect(closed.barNumber(containing: 1) == 2)
        #expect(closed.barNumber(containing: beatTime(frac(3, 2))) == 3)
        #expect(open.barNumber(containing: 10) == 12)
    }

    @Test
    func barNumber_containing_freeSpan() {
        #expect(free.barNumber(containing: beatTime(frac(5, 2))) == 4)
    }

    @Test
    func barStart() {
        #expect(closed.barStart(1) == 0)
        #expect(closed.barStart(3) == beatTime(frac(3, 2)))
        #expect(open.barStart(7) == 5)
    }

    @Test
    func barStart_freeSpan_isSpanStart() {
        #expect(free.barStart(4) == 2)
    }

    @Test
    func contains_barNumber() {
        #expect(!closed.contains(barNumber: 0))
        #expect(closed.contains(barNumber: 1))
        #expect(closed.contains(barNumber: 3))
        #expect(!closed.contains(barNumber: 4))
    }

    @Test
    func contains_barNumber_openSpan() {
        #expect(!open.contains(barNumber: 4))
        #expect(open.contains(barNumber: 100))
    }

    @Test
    func isOnBarline() {
        #expect(closed.isOnBarline(0))
        #expect(closed.isOnBarline(beatTime(frac(3, 2))))
        #expect(!closed.isOnBarline(1))
    }

    @Test
    func isOnBarline_freeSpan_onlyAtStart() {
        #expect(free.isOnBarline(2))
        #expect(!free.isOnBarline(beatTime(frac(5, 2))))
    }
}
