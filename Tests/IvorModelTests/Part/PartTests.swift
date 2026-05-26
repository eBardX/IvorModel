// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing

struct PartTests {
}

// MARK: -

extension PartTests {
    @Test
    func codable() throws {
        let original = Part<BeatTime, Pitch>(name: "Violin")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Part<BeatTime, Pitch>.self, from: data)

        #expect(decoded.name == original.name)
        #expect(decoded.timeRange == nil)
        #expect(decoded.dynamicMap.isEmpty)
        #expect(decoded.instrumentMap.isEmpty)
        #expect(decoded.panMap.isEmpty)
    }

    @Test
    func init_defaults() {
        let part = Part<BeatTime, Pitch>(name: "Piano")

        #expect(part.name == "Piano")
        #expect(part.timeRange == nil)
        #expect(part.dynamicMap.isEmpty)
        #expect(part.instrumentMap.isEmpty)
        #expect(part.panMap.isEmpty)
    }

    @Test
    func init_name() {
        let part = Part<BeatTime, Pitch>(name: "Cello")

        #expect(part.name == "Cello")
    }

    @Test
    func timeRange_empty() {
        let part = Part<BeatTime, Pitch>(name: "Flute")

        #expect(part.timeRange == nil)
    }
}
