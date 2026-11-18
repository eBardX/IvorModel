// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov

struct TemplateContentVisitorTests {
}

// MARK: -

extension TemplateContentVisitorTests {
    @Test
    func visit_optionalResult_isNilWithoutChain() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let template = Template(name: "T", content: .standardBeat(Template.Model(chains: .joint(markovChain))))

        #expect(template.accept(BeginCountVisitor(role: .joint)) == 0)
        #expect(template.accept(BeginCountVisitor(role: .pitch)) == nil)
    }

    @Test
    func visit_receivesTemplatesModel() throws {
        let markovChain = try #require(MarkovChain<Template.State<WallTime, Frequency>>(maximumOrder: 2))
        let template = Template(name: "T", content: .absoluteWall(Template.Model(chains: .joint(markovChain))))

        #expect(template.accept(MaximumOrderVisitor()) == 2)
        #expect(template.accept(TypeNameVisitor()) == "WallTime Frequency")
    }
}
