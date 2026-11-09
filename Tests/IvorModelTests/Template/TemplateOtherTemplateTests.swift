// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

struct TemplateOtherTemplateTests {
}

// MARK: -

extension TemplateOtherTemplateTests {
    @Test
    func codable() throws {
        let original = Template.OtherTemplate(templateID: TemplateID(), templateName: "Other")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Template.OtherTemplate.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func hashable() {
        let templateID = TemplateID()
        let others: Set = [Template.OtherTemplate(templateID: templateID, templateName: "A"),
                           Template.OtherTemplate(templateID: templateID, templateName: "A"),
                           Template.OtherTemplate(templateID: templateID, templateName: "B")]

        #expect(others.count == 2)
    }

    @Test
    func init_fromTemplate_copiesIDAndName() throws {
        let template = try makeBranchingTemplate()
        let other = Template.OtherTemplate(template)

        #expect(other.templateID == template.templateID)
        #expect(other.templateName == template.name)
    }

    @Test
    func init_storesValues() {
        let templateID = TemplateID()
        let other = Template.OtherTemplate(templateID: templateID, templateName: "Other")

        #expect(other.templateID == templateID)
        #expect(other.templateName == "Other")
    }
}
