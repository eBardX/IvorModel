// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

struct TemplateGenerationOptionsShareTests {
}

// MARK: -

extension TemplateGenerationOptionsShareTests {
    @Test
    func codable() throws {
        let original = StandardBeatOptions.Share(template: .init(templateID: TemplateID(), templateName: "Other"),
                                                 weight: 0.25)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StandardBeatOptions.Share.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func hashable() {
        let other = Template.OtherTemplate(templateID: TemplateID(), templateName: "Other")
        let shares: Set = [StandardBeatOptions.Share(template: other, weight: 0.5),
                           StandardBeatOptions.Share(template: other, weight: 0.5),
                           StandardBeatOptions.Share(template: other, weight: 0.25)]

        #expect(shares.count == 2)
    }

    @Test
    func init_storesValues() {
        let other = Template.OtherTemplate(templateID: TemplateID(), templateName: "Other")
        let share = StandardBeatOptions.Share(template: other, weight: 0.75)

        #expect(share.template == other)
        #expect(share.weight == 0.75)
    }
}
