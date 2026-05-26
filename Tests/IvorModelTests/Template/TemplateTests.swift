// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
@testable import IvorTuning
import Testing
import XestiMarkov

struct TemplateTests {
}

// MARK: -

extension TemplateTests {
    @Test
    func comparable() throws {
        let markovChain = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let alpha  = Template(name: "Alpha", content: .standardBeat(markovChain))
        let beta   = Template(name: "Beta", content: .standardBeat(markovChain))

        #expect(alpha < beta)
        #expect(!(beta < alpha))
    }

    @Test
    func currentVersion() {
        #expect(Template.currentVersion == 1)
    }

    @Test
    func equality() throws {
        let markovChain = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let tmpl = Template(name: "My Template", content: .standardBeat(markovChain))

        #expect(tmpl == tmpl) // swiftlint:disable:this identical_operands
    }

    @Test
    func inequality() throws {
        let markovChain = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let tmpl1  = Template(name: "My Template", content: .standardBeat(markovChain))
        let tmpl2  = Template(name: "My Template", content: .standardBeat(markovChain))

        #expect(tmpl1 != tmpl2)
    }

    @Test
    func init_properties() throws {
        let markovChain = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let tmpl = Template(name: "Fugue", content: .standardBeat(markovChain))

        #expect(tmpl.name == "Fugue")
        #expect(tmpl.version == Template.currentVersion)
    }
}
