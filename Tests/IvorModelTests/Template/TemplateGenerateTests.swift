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

// MARK: - Ties (F1)

extension TemplateGenerateTests {
    @Test
    func generateWork_order1_noRepeatedStates_reproducesSource() throws {
        // Overlapping notes, a chord with staggered releases, and leading and
        // inner rests. No state repeats, so the order-1 chain is deterministic.
        let source = makeNoteTableSB([(0.5, 1, .a4),
                                      (1, 1, .cSharp5),
                                      (3, 3, .e5),
                                      (3, 1, .g5),
                                      (3, 2, .b5)])
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>(maximumOrder: 1))

        mc.analyzer().analyze(sequence: source.extractNoteEvents())

        let tmpl = Template(name: "Test", content: .standardBeat(mc))
        let work = try tmpl.generateWork(name: "Generated",
                                         order: 1,
                                         limit: 100)

        guard case let .standardBeat(parts, _) = work.content
        else { Issue.record("Unexpected content"); return }

        let generated = try #require(parts.first).noteTable

        #expect(makeNoteTriplesSB(generated) == makeNoteTriplesSB(source))
    }
}
