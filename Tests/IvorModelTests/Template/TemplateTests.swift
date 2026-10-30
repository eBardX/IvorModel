// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
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
        let absoluteBeat = try #require(MarkovChain<Template.State<BeatTime, Frequency>>())
        let absoluteWall = try #require(MarkovChain<Template.State<WallTime, Frequency>>())
        let keyboardBeat = try #require(MarkovChain<Template.State<BeatTime, NoteNumber>>())
        let keyboardWall = try #require(MarkovChain<Template.State<WallTime, NoteNumber>>())
        let standardBeat = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let standardWall = try #require(MarkovChain<Template.State<WallTime, Pitch>>())
        let visitor = _TypeNameVisitor()

        #expect(Template(name: "T", content: .absoluteBeat(Template.Model(chains: .joint(absoluteBeat)))).accept(visitor) == "BeatTime Frequency")
        #expect(Template(name: "T", content: .absoluteWall(Template.Model(chains: .joint(absoluteWall)))).accept(visitor) == "WallTime Frequency")
        #expect(Template(name: "T", content: .keyboardBeat(Template.Model(chains: .joint(keyboardBeat)))).accept(visitor) == "BeatTime NoteNumber")
        #expect(Template(name: "T", content: .keyboardWall(Template.Model(chains: .joint(keyboardWall)))).accept(visitor) == "WallTime NoteNumber")
        #expect(Template(name: "T", content: .standardBeat(Template.Model(chains: .joint(standardBeat)))).accept(visitor) == "BeatTime Pitch")
        #expect(Template(name: "T", content: .standardWall(Template.Model(chains: .joint(standardWall)))).accept(visitor) == "WallTime Pitch")
    }

    @Test
    func accept_passesMarkovChain() throws {
        let markovChain = try #require(MarkovChain<Template.State<WallTime, NoteNumber>>(maximumOrder: 3))
        let tmpl = Template(name: "T", content: .keyboardWall(Template.Model(chains: .joint(markovChain))))

        #expect(tmpl.accept(_MaximumOrderVisitor()) == 3)
    }

    @Test
    func codable_normalizesName() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let data = try JSONEncoder().encode(Template(name: "T", content: .standardBeat(Template.Model(chains: .joint(markovChain)))))
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        object["name"] = "  My \n Template "

        let decoded = try JSONDecoder().decode(Template.self,
                                               from: JSONSerialization.data(withJSONObject: object))

        #expect(decoded.name == "My Template")
    }

    @Test
    func codable_oldVersion_throwsUnsupportedVersion() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let data = try JSONEncoder().encode(Template(name: "T", content: .standardBeat(Template.Model(chains: .joint(markovChain)))))
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        object["version"] = 3
        object["analysisOptions"] = nil

        #expect(throws: Template.Error.unsupportedVersion(3)) {
            try JSONDecoder().decode(Template.self,
                                     from: JSONSerialization.data(withJSONObject: object))
        }
    }

    @Test
    func comparable() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let alpha  = Template(name: "Alpha", content: .standardBeat(Template.Model(chains: .joint(markovChain))))
        let beta   = Template(name: "Beta", content: .standardBeat(Template.Model(chains: .joint(markovChain))))

        #expect(alpha < beta)
        #expect(!(beta < alpha))
    }

    @Test
    func currentVersion() {
        #expect(Template.currentVersion == 1)
    }

    @Test
    func equality() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let tmpl = Template(name: "My Template", content: .standardBeat(Template.Model(chains: .joint(markovChain))))

        #expect(tmpl == tmpl) // swiftlint:disable:this identical_operands
    }

    @Test
    func inequality() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let tmpl1  = Template(name: "My Template", content: .standardBeat(Template.Model(chains: .joint(markovChain))))
        let tmpl2  = Template(name: "My Template", content: .standardBeat(Template.Model(chains: .joint(markovChain))))

        #expect(tmpl1 != tmpl2)
    }

    @Test
    func init_normalizesName() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())

        #expect(Template(name: " My\t Template ", content: .standardBeat(Template.Model(chains: .joint(markovChain)))).name == "My Template")
    }

    @Test
    func init_properties() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let tmpl = Template(name: "Fugue", content: .standardBeat(Template.Model(chains: .joint(markovChain))))

        #expect(tmpl.name == "Fugue")
        #expect(tmpl.version == Template.currentVersion)
    }

    @Test
    func isLocked_default() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let tmpl = Template(name: "Fugue", content: .standardBeat(Template.Model(chains: .joint(markovChain))))

        #expect(!tmpl.isLocked)
    }

    @Test
    func maximumOrder() throws {
        let mc = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let tmpl = Template(name: "Test", content: .standardBeat(Template.Model(chains: .joint(mc))))

        #expect(tmpl.maximumOrder >= 0)
    }

    @Test
    func metrics_empty() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>(maximumOrder: 2))
        let metrics = try #require(Template(name: "T", content: .standardBeat(Template.Model(chains: .joint(markovChain)))).metrics(for: .joint))

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

        guard case let .standardBeat(model) = tmpl.content
        else { Issue.record("Unexpected content"); return }

        let expected = try #require(model.chains.chain(for: .joint)).metrics()
        let metrics = try #require(tmpl.metrics(for: .joint))

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
        let mc = try #require(MarkovChain<Template.State<BeatTime, Frequency>>())
        let tmpl = Template(name: "Test", content: .absoluteBeat(Template.Model(chains: .joint(mc))))

        #expect(tmpl.pitchNotation == .absolute)
    }

    @Test
    func pitchNotation_keyboard() throws {
        let mc = try #require(MarkovChain<Template.State<BeatTime, NoteNumber>>())
        let tmpl = Template(name: "Test", content: .keyboardBeat(Template.Model(chains: .joint(mc))))

        #expect(tmpl.pitchNotation == .keyboard)
    }

    @Test
    func pitchNotation_standard() throws {
        let mc = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let tmpl = Template(name: "Test", content: .standardBeat(Template.Model(chains: .joint(mc))))

        #expect(tmpl.pitchNotation == .standard)
    }

    @Test
    func rename() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        var tmpl = Template(name: "Original", content: .standardBeat(Template.Model(chains: .joint(markovChain))))

        try tmpl.rename(to: "Renamed")

        #expect(tmpl.name == "Renamed")
    }

    @Test
    func rename_locked_throws() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        var tmpl = Template(name: "Original", content: .standardBeat(Template.Model(chains: .joint(markovChain))))

        tmpl.isLocked = true

        #expect(throws: Template.Error.templateIsLocked) {
            try tmpl.rename(to: "Renamed")
        }
        #expect(tmpl.name == "Original")
    }

    @Test
    func rename_normalizesName() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        var tmpl = Template(name: "Original", content: .standardBeat(Template.Model(chains: .joint(markovChain))))

        try tmpl.rename(to: "  Re  named ")

        #expect(tmpl.name == "Re named")
    }

    @Test
    func timeBasis_beat() throws {
        let mc = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let tmpl = Template(name: "Test", content: .standardBeat(Template.Model(chains: .joint(mc))))

        #expect(tmpl.timeBasis == .beat)
    }

    @Test
    func timeBasis_wall() throws {
        let mc = try #require(MarkovChain<Template.State<WallTime, Pitch>>())
        let tmpl = Template(name: "Test", content: .standardWall(Template.Model(chains: .joint(mc))))

        #expect(tmpl.timeBasis == .wall)
    }
}

// MARK: -

extension TemplateTests {
    private struct _MaximumOrderVisitor: Template.ContentVisitor {
        func visit<TimeType>(_ model: Template.Model<TimeType, some Any>) -> Int where TimeType.DurationType: TemplateDuration {
            model.chains.maximumOrder
        }
    }

    private struct _TypeNameVisitor: Template.ContentVisitor {
        func visit<TimeType, PitchType>(_ model: Template.Model<TimeType, PitchType>) -> String where TimeType.DurationType: TemplateDuration {
            "\(TimeType.self) \(PitchType.self)"
        }
    }
}
