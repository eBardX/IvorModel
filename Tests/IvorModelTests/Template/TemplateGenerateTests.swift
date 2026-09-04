// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers

struct TemplateGenerateTests {
}

// MARK: -

extension TemplateGenerateTests {
    @Test
    func generateWork_invalidLimit() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let tmpl = Template(name: "Test", content: .standardBeat(mc))

        #expect(throws: Template.Error.self) {
            try tmpl.generateWork(name: "Generated",
                                  order: 1,
                                  limit: 0)
        }
    }

    @Test
    func generateWork_invalidOrder() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>(maximumOrder: 1))
        let tmpl = Template(name: "Test", content: .standardBeat(mc))

        #expect(throws: Template.Error.self) {
            try tmpl.generateWork(name: "Generated",
                                  order: 5,
                                  limit: 4)
        }
    }

    @Test
    func generateWork_success() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>(maximumOrder: 1))
        let event = NoteEvent<BeatTime, Pitch>(tiedPitches: [NoteEvent<BeatTime, Pitch>.TiedPitch(pitch: .c4)],
                                               duration: 1)

        mc.analyzer().analyze(sequence: [event, event])

        let tmpl = Template(name: "Test", content: .standardBeat(mc))

        let work = try tmpl.generateWork(name: "Generated",
                                         order: 1,
                                         limit: 4)

        #expect(work.name == "Generated")
        #expect(work.pitchNotation == .standard)
        #expect(work.timeBasis == .beat)
        #expect(work.partCount == 1)
    }
}
