// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct ProjectSkippedTemplateTests {
}

// MARK: -

extension ProjectSkippedTemplateTests {
    @Test
    func equality() {
        let templateID = TemplateID()

        #expect(Project.SkippedTemplate(templateID: templateID, name: "A", reason: "Old") // swiftlint:disable:this identical_operands
                == Project.SkippedTemplate(templateID: templateID, name: "A", reason: "Old"))
    }

    @Test
    func hashable() {
        let templateID = TemplateID()
        let skipped: Set = [Project.SkippedTemplate(templateID: templateID, name: "A", reason: "Old"),
                            Project.SkippedTemplate(templateID: templateID, name: "A", reason: "Old"),
                            Project.SkippedTemplate(templateID: TemplateID(), name: "A", reason: "Old")]

        #expect(skipped.count == 2)
    }

    @Test
    func inequality_differentReason() {
        let templateID = TemplateID()

        #expect(Project.SkippedTemplate(templateID: templateID, name: "A", reason: "Old")
                != Project.SkippedTemplate(templateID: templateID, name: "A", reason: "Corrupt"))
    }

    @Test
    func init_storesValues() {
        let templateID = TemplateID()
        let skipped = Project.SkippedTemplate(templateID: templateID,
                                              name: "Tune",
                                              reason: "Unsupported version")

        #expect(skipped.name == "Tune")
        #expect(skipped.reason == "Unsupported version")
        #expect(skipped.templateID == templateID)
    }

    @Test
    func init_withoutName() {
        let skipped = Project.SkippedTemplate(templateID: TemplateID(),
                                              name: nil,
                                              reason: "Missing")

        #expect(skipped.name == nil)
    }
}
