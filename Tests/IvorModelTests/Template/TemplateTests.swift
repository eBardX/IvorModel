// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
@testable import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers

struct TemplateTests {
}

// MARK: -

extension TemplateTests {
    @Test
    func accept() throws {
        let absoluteBeat = try #require(MarkovChain<NoteEvent<BeatTime, Frequency>>())
        let absoluteWall = try #require(MarkovChain<NoteEvent<WallTime, Frequency>>())
        let keyboardBeat = try #require(MarkovChain<NoteEvent<BeatTime, NoteNumber>>())
        let keyboardWall = try #require(MarkovChain<NoteEvent<WallTime, NoteNumber>>())
        let standardBeat = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let standardWall = try #require(MarkovChain<NoteEvent<WallTime, Pitch>>())
        let visitor = _TypeNameVisitor()

        #expect(Template(name: "T", content: .absoluteBeat(absoluteBeat)).accept(visitor) == "BeatTime Frequency")
        #expect(Template(name: "T", content: .absoluteWall(absoluteWall)).accept(visitor) == "WallTime Frequency")
        #expect(Template(name: "T", content: .keyboardBeat(keyboardBeat)).accept(visitor) == "BeatTime NoteNumber")
        #expect(Template(name: "T", content: .keyboardWall(keyboardWall)).accept(visitor) == "WallTime NoteNumber")
        #expect(Template(name: "T", content: .standardBeat(standardBeat)).accept(visitor) == "BeatTime Pitch")
        #expect(Template(name: "T", content: .standardWall(standardWall)).accept(visitor) == "WallTime Pitch")
    }

    @Test
    func accept_passesMarkovChain() throws {
        let markovChain = try #require(MarkovChain<NoteEvent<WallTime, NoteNumber>>(maximumOrder: 3))
        let tmpl = Template(name: "T", content: .keyboardWall(markovChain))

        #expect(tmpl.accept(_MaximumOrderVisitor()) == 3)
    }

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

    @Test
    func maximumOrder() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let tmpl = Template(name: "Test", content: .standardBeat(mc))

        #expect(tmpl.maximumOrder >= 0)
    }

    @Test
    func metrics_empty() throws {
        let markovChain = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>(maximumOrder: 2))
        let metrics = Template(name: "T", content: .standardBeat(markovChain)).metrics

        #expect(metrics.order == 2)
        #expect(metrics.recommendedOrder == nil)
        #expect(metrics.stateCount == 0)
        #expect(metrics.transitionCount == 0)
        #expect(metrics.branchingRatio == 0)
    }

    @Test
    func metrics_trained() throws {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .e4)
        table.insert(attack: 2, duration: 1, pitch: .c4)
        table.insert(attack: 3, duration: 2, pitch: .g4)

        let work = Work(name: "W", content: .standardBeat([Part(name: "Piano", noteTable: table)], TempoMap()))
        let tmpl = try Template.analyzeNoteEvents(in: work, at: 0, maximumOrder: 1)

        guard case let .standardBeat(markovChain) = tmpl.content
        else { Issue.record("Unexpected content"); return }

        let expected = markovChain.metrics()
        let metrics = tmpl.metrics

        #expect(metrics.order == 1)
        #expect(metrics.recommendedOrder == expected.recommendedOrder)
        #expect(metrics.stateCount == expected.distinctStates)
        #expect(metrics.stateCount == 3)
        #expect(metrics.transitionCount == expected.orderMetrics[1].totalTransitions)
        #expect(metrics.transitionCount > 0)
        #expect(metrics.branchingRatio == expected.orderMetrics[1].branchingRatio)
        #expect(metrics.branchingRatio > 0)
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
    func rename() throws {
        let markovChain = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        var tmpl = Template(name: "Original", content: .standardBeat(markovChain))

        try tmpl.rename(to: "Renamed")

        #expect(tmpl.name == "Renamed")
    }

    @Test
    func rename_locked_throws() throws {
        let markovChain = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        var tmpl = Template(name: "Original", content: .standardBeat(markovChain))

        tmpl.isLocked = true

        #expect(throws: Template.Error.templateIsLocked) {
            try tmpl.rename(to: "Renamed")
        }
        #expect(tmpl.name == "Original")
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

// MARK: -

extension TemplateTests {
    private struct _MaximumOrderVisitor: Template.ContentVisitor {
        func visit(_ markovChain: MarkovChain<NoteEvent<some TimeProtocol, some PitchProtocol>>) -> Int {
            markovChain.maximumOrder
        }
    }

    private struct _TypeNameVisitor: Template.ContentVisitor {
        func visit<TimeType: TimeProtocol, PitchType: PitchProtocol>(_ markovChain: MarkovChain<NoteEvent<TimeType, PitchType>>) -> String {
            "\(TimeType.self) \(PitchType.self)"
        }
    }
}
