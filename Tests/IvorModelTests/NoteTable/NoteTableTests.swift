// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableTests {
}

// MARK: -

extension NoteTableTests {
    private typealias NoteTableSB = NoteTable<BeatTime, Pitch>

    @Test
    func codable() throws {
        var original = NoteTableSB()

        original.insert(attack: 0, duration: 1, pitch: .c4)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NoteTableSB.self,
                                               from: data)

        #expect(decoded.pitchRange == original.pitchRange)
        #expect(decoded.timeRange == original.timeRange)
    }

    @Test
    func hasExtras_initial() {
        let table = NoteTableSB()

        #expect(!table.hasExtras)
    }

    @Test
    func hasPortamento_initial() {
        let table = NoteTableSB()

        #expect(!table.hasPortamento)
    }

    @Test
    func init_empty() {
        let table = NoteTableSB()

        #expect(table.isEmpty)
        #expect(table.pitchRange == nil)
        #expect(table.timeRange == nil)
    }

    @Test
    func isMonophonic_initial() {
        let table = NoteTableSB()

        #expect(table.isMonophonic)
    }

    @Test
    func pitchRange_initial() {
        let table = NoteTableSB()

        #expect(table.pitchRange == nil)
    }

    @Test
    func timeRange_initial() {
        let table = NoteTableSB()

        #expect(table.timeRange == nil)
    }
}
