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

    @Test
    func isLocked_default() throws {
        let markovChain = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let tmpl = Template(name: "Fugue", content: .standardBeat(markovChain))

        #expect(!tmpl.isLocked)
    }

    //
    // This type's `name` setter has no locked-check of its own — see `isLocked`'s doc comment —
    // so renaming a locked template here succeeds; it's `ProjectDocument` that's expected to
    // refuse to rename (or delete) a locked template before ever reaching this setter.
    //

    @Test
    func isLocked_nameSetterHasNoGuard() throws {
        let markovChain = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        var tmpl = Template(name: "Original", content: .standardBeat(markovChain))

        tmpl.isLocked = true
        tmpl.name = "Renamed"

        #expect(tmpl.name == "Renamed")
    }

    @Test
    func maximumOrder() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let tmpl = Template(name: "Test", content: .standardBeat(mc))

        #expect(tmpl.maximumOrder >= 0)
    }

    @Test
    func pitchNotation_absolute() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Frequency>>())
        let tmpl = Template(name: "Test", content: .absoluteBeat(mc))

        #expect(tmpl.pitchNotation == .absolute)
    }

    @Test
    func pitchNotation_keyboard() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, NoteNumber>>())
        let tmpl = Template(name: "Test", content: .keyboardBeat(mc))

        #expect(tmpl.pitchNotation == .keyboard)
    }

    @Test
    func pitchNotation_standard() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let tmpl = Template(name: "Test", content: .standardBeat(mc))

        #expect(tmpl.pitchNotation == .standard)
    }

    @Test
    func timeBasis_beat() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let tmpl = Template(name: "Test", content: .standardBeat(mc))

        #expect(tmpl.timeBasis == .beat)
    }

    @Test
    func timeBasis_wall() throws {
        let mc = try #require(MarkovChain<NoteEvent<WallTime, Pitch>>())
        let tmpl = Template(name: "Test", content: .standardWall(mc))

        #expect(tmpl.timeBasis == .wall)
    }
}
