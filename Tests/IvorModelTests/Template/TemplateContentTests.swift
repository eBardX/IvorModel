// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
@testable import IvorTuning
import Testing
import XestiMarkov

struct TemplateContentTests {
}

// MARK: -

extension TemplateContentTests {
    @Test
    func codable_beat() throws {
        let mc = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let original: Template.Content = .standardBeat(Template.Model(markovChain: mc))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Template.Content.self,
                                               from: data)

        #expect(decoded.pitchNotation == original.pitchNotation)
        #expect(decoded.timeBasis == original.timeBasis)
    }

    @Test
    func codable_wall() throws {
        let mc = try #require(MarkovChain<Template.State<WallTime, Pitch>>())
        let original: Template.Content = .standardWall(Template.Model(markovChain: mc))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Template.Content.self,
                                               from: data)

        #expect(decoded.pitchNotation == original.pitchNotation)
        #expect(decoded.timeBasis == original.timeBasis)
    }

    @Test
    func pitchNotation_absolute() throws {
        let mc = try #require(MarkovChain<Template.State<WallTime, Frequency>>())
        let content: Template.Content = .absoluteWall(Template.Model(markovChain: mc))

        #expect(content.pitchNotation == .absolute)
    }

    @Test
    func pitchNotation_keyboard() throws {
        let mc = try #require(MarkovChain<Template.State<WallTime, NoteNumber>>())
        let content: Template.Content = .keyboardWall(Template.Model(markovChain: mc))

        #expect(content.pitchNotation == .keyboard)
    }

    @Test
    func pitchNotation_standard() throws {
        let mc = try #require(MarkovChain<Template.State<WallTime, Pitch>>())
        let content: Template.Content = .standardWall(Template.Model(markovChain: mc))

        #expect(content.pitchNotation == .standard)
    }

    @Test
    func timeBasis_beat() throws {
        let mc = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let content: Template.Content = .standardBeat(Template.Model(markovChain: mc))

        #expect(content.timeBasis == .beat)
    }

    @Test
    func timeBasis_wall() throws {
        let mc = try #require(MarkovChain<Template.State<WallTime, Pitch>>())
        let content: Template.Content = .standardWall(Template.Model(markovChain: mc))

        #expect(content.timeBasis == .wall)
    }
}
