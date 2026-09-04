// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing

struct WorkContentTests {
}

// MARK: -

extension WorkContentTests {
    @Test
    func codable_beat() throws {
        let original: Work.Content = .standardBeat([Part<BeatTime, Pitch>(name: "Piano")],
                                                   TempoMap())
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Work.Content.self,
                                               from: data)

        #expect(decoded.pitchNotation == original.pitchNotation)
        #expect(decoded.timeBasis == original.timeBasis)
    }

    @Test
    func codable_wall() throws {
        let original: Work.Content = .standardWall([Part<WallTime, Pitch>(name: "Piano")])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Work.Content.self,
                                               from: data)

        #expect(decoded.pitchNotation == original.pitchNotation)
        #expect(decoded.timeBasis == original.timeBasis)
    }

    @Test
    func pitchNotation_absolute() {
        let content: Work.Content = .absoluteWall([])

        #expect(content.pitchNotation == .absolute)
    }

    @Test
    func pitchNotation_keyboard() {
        let content: Work.Content = .keyboardWall([])

        #expect(content.pitchNotation == .keyboard)
    }

    @Test
    func pitchNotation_standard() {
        let content: Work.Content = .standardWall([])

        #expect(content.pitchNotation == .standard)
    }

    @Test
    func timeBasis_beat() {
        let content: Work.Content = .standardBeat([], TempoMap())

        #expect(content.timeBasis == .beat)
    }

    @Test
    func timeBasis_wall() {
        let content: Work.Content = .standardWall([])

        #expect(content.timeBasis == .wall)
    }
}
