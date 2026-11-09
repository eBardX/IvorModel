// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct WorkGenerationTests {
}

// MARK: -

extension WorkGenerationTests {
    @Test
    func codable() throws {
        let original = Work.Generation(templateID: TemplateID(),
                                       templateName: "Tune",
                                       options: .standardBeat(StandardBeatOptions(order: 2)),
                                       seed: 42)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Work.Generation.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func hashable() {
        let templateID = TemplateID()
        let options = Template.AnyGenerationOptions.standardBeat(StandardBeatOptions())
        let generations: Set = [Work.Generation(templateID: templateID, templateName: "A", options: options, seed: 1),
                                Work.Generation(templateID: templateID, templateName: "A", options: options, seed: 1),
                                Work.Generation(templateID: templateID, templateName: "A", options: options, seed: 2)]

        #expect(generations.count == 2)
    }

    @Test
    func inequality_differentOptions() {
        let templateID = TemplateID()

        #expect(Work.Generation(templateID: templateID,
                                templateName: "A",
                                options: .standardBeat(StandardBeatOptions(order: 1)),
                                seed: 1)
                != Work.Generation(templateID: templateID,
                                   templateName: "A",
                                   options: .standardBeat(StandardBeatOptions(order: 2)),
                                   seed: 1))
    }

    @Test
    func init_storesValues() {
        let templateID = TemplateID()
        let options = Template.AnyGenerationOptions.standardBeat(StandardBeatOptions())
        let generation = Work.Generation(templateID: templateID,
                                         templateName: "Tune",
                                         options: options,
                                         seed: 7)

        #expect(generation.options == options)
        #expect(generation.seed == 7)
        #expect(generation.templateID == templateID)
        #expect(generation.templateName == "Tune")
    }
}
