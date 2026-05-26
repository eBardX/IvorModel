// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov

struct TemplateContentTests {
}

// MARK: -

extension TemplateContentTests {
    @Test
    func maximumOrder() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let content = Template.Content.standardBeat(mc)

        #expect(content.maximumOrder >= 0)
    }

    @Test
    func pitchNotation_absolute() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Frequency>>())
        let content = Template.Content.absoluteBeat(mc)

        #expect(content.pitchNotation == .absolute)
    }

    @Test
    func pitchNotation_keyboard() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, NoteNumber>>())
        let content = Template.Content.keyboardBeat(mc)

        #expect(content.pitchNotation == .keyboard)
    }

    @Test
    func pitchNotation_standard() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let content = Template.Content.standardBeat(mc)

        #expect(content.pitchNotation == .standard)
    }

    @Test
    func timeBasis_beat() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let content = Template.Content.standardBeat(mc)

        #expect(content.timeBasis == .beat)
    }

    @Test
    func timeBasis_wall() throws {
        let mc = try #require(MarkovChain<NoteEvent<WallTime, Pitch>>())
        let content = Template.Content.standardWall(mc)

        #expect(content.timeBasis == .wall)
    }
}
