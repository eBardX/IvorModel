// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct PartMarkTableTransformTests {
}

// MARK: -

extension PartMarkTableTransformTests {
    private typealias Table = PartMarkTable<BeatTime>

    @Test
    func augment_errors() {
        var table = markedTable()

        #expect(throws: Table.Error.invalidAugmentationFactor(frac(1, 2))) {
            try table.augment(by: frac(1, 2))
        }

        #expect(throws: Table.Error.invalidAnchor) {
            try table.augment(by: 2, anchor: 2)
        }
    }

    @Test
    func augment_scalesTimesAndSpans() throws {
        var table = markedTable()

        try table.augment(by: 2)

        #expect(table.map(\.time) == [1, 3])
        #expect(table.map(\.mark) == [fermataMark(beats(frac(1, 2))), .caesura(nil)])
    }

    @Test
    func augment_selectedEntriesOnly() throws {
        var table = markedTable()
        let caesuraID = try #require(table.last?.entryID)

        try table.augment(by: 2, anchor: 0, entryIDs: [caesuraID])

        #expect(table.map(\.time) == [1, 4])
    }

    @Test
    func diminish_scalesTimesAndSpans() throws {
        var table = markedTable()

        try table.diminish(by: 2, anchor: 0)

        #expect(table.map(\.time) == [beatTime(frac(1, 2)), 1])
        #expect(table.first?.mark == fermataMark(beats(frac(1, 8))))
    }

    @Test
    func move_keepsSpans() throws {
        var table = markedTable()

        try table.move(by: DirectedDuration(duration: beats(1), direction: .forward))

        #expect(table.map(\.time) == [2, 3])
        #expect(table.first?.mark == fermataMark(beats(frac(1, 4))))

        #expect(throws: Table.Error.moveFailure(2)) {
            try table.move(by: DirectedDuration(duration: beats(3), direction: .backward))
        }
    }

    @Test
    func quantize_snapsTimesAndSpanEnds() throws {
        let quantizer = try BeatQuantizer(factors: [2])
        let start = beatTime(frac(1, 3))
        let end = beatTime(frac(5, 3))
        var table = Table()

        table.insert(time: start, mark: fermataMark(end - start))
        table.insert(time: 1, mark: fermataMark(beats(frac(1, 1_000))))

        table.quantize(using: quantizer)

        let newStart = quantizer.quantize(start)

        #expect(table.map(\.time) == [newStart, 1].sorted())
        #expect(table.first { $0.time == newStart }?.mark == fermataMark(quantizer.quantize(end) - newStart))
        //
        // A span that snaps to nothing keeps one grid unit:
        //
        #expect(table.first { $0.time == 1 }?.mark == fermataMark(quantizer.gridUnit))
    }

    @Test
    func reverse_errors() {
        var table = markedTable()

        #expect(throws: Table.Error.invalidAnchor) {
            try table.reverse(within: 2...3)
        }
    }

    @Test
    func reverse_mirrorsSpansAndMoments() throws {
        var table = Table()

        table.insert(time: 0, mark: fermataMark(beats(1)))
        table.insert(time: 3, mark: .caesura(nil))

        try table.reverse(within: 0...4)

        //
        // The fermata over 0…1 mirrors to 3…4; the caesura at 3 to 1.
        //
        #expect(table.map(\.time) == [1, 3])
        #expect(table.map(\.mark) == [.caesura(nil), fermataMark(beats(1))])
    }

    @Test
    func timeRange_includesFermataEnds() {
        var table = Table()

        #expect(table.timeRange == nil)

        table.insert(time: 1, mark: fermataMark(beats(3)))
        table.insert(time: 2, mark: .caesura(nil))

        #expect(table.timeRange == 1...4)
    }
}
