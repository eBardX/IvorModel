// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct TemplateAnyGenerationOptionsTests {
}

// MARK: -

extension TemplateAnyGenerationOptionsTests {
    @Test
    func codable() throws {
        let originals: [Template.AnyGenerationOptions] = [.absoluteWall(.init(order: 2)),
                                                          .keyboardBeat(.init(length: .noteCount(12))),
                                                          .standardBeat(StandardBeatOptions(order: 3))]

        for original in originals {
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(Template.AnyGenerationOptions.self,
                                                   from: data)

            #expect(decoded == original)
        }
    }

    @Test
    func hashable() {
        let options: Set<Template.AnyGenerationOptions> = [.standardBeat(StandardBeatOptions()),
                                                           .standardBeat(StandardBeatOptions()),
                                                           .standardWall(.init())]

        #expect(options.count == 2)
    }

    @Test
    func init_absolute() {
        #expect(Template.AnyGenerationOptions(Template.GenerationOptions<BeatTime, Frequency>()) == .absoluteBeat(.init()))
        #expect(Template.AnyGenerationOptions(Template.GenerationOptions<WallTime, Frequency>()) == .absoluteWall(.init()))
    }

    @Test
    func init_keyboard() {
        #expect(Template.AnyGenerationOptions(Template.GenerationOptions<BeatTime, NoteNumber>()) == .keyboardBeat(.init()))
        #expect(Template.AnyGenerationOptions(Template.GenerationOptions<WallTime, NoteNumber>()) == .keyboardWall(.init()))
    }

    @Test
    func init_standard() {
        #expect(Template.AnyGenerationOptions(StandardBeatOptions(order: 2)) == .standardBeat(StandardBeatOptions(order: 2)))
        #expect(Template.AnyGenerationOptions(Template.GenerationOptions<WallTime, Pitch>()) == .standardWall(.init()))
    }

    @Test
    func otherTemplates_withoutTemplateMix_isEmpty() {
        #expect(Template.AnyGenerationOptions.standardBeat(StandardBeatOptions()).otherTemplates.isEmpty)
    }

    @Test
    func otherTemplates_withTemplateMix() {
        let other = Template.OtherTemplate(templateID: TemplateID(), templateName: "Other")
        let options = Template.AnyGenerationOptions.standardBeat(StandardBeatOptions(templateMix: .blend([.init(template: other,
                                                                                                                weight: 0.5)])))

        #expect(options.otherTemplates == [other])
    }

    @Test
    func pitchNotation() {
        #expect(Template.AnyGenerationOptions.absoluteBeat(.init()).pitchNotation == .absolute)
        #expect(Template.AnyGenerationOptions.absoluteWall(.init()).pitchNotation == .absolute)
        #expect(Template.AnyGenerationOptions.keyboardBeat(.init()).pitchNotation == .keyboard)
        #expect(Template.AnyGenerationOptions.keyboardWall(.init()).pitchNotation == .keyboard)
        #expect(Template.AnyGenerationOptions.standardBeat(.init()).pitchNotation == .standard)
        #expect(Template.AnyGenerationOptions.standardWall(.init()).pitchNotation == .standard)
    }

    @Test
    func timeBasis() {
        #expect(Template.AnyGenerationOptions.absoluteBeat(.init()).timeBasis == .beat)
        #expect(Template.AnyGenerationOptions.absoluteWall(.init()).timeBasis == .wall)
        #expect(Template.AnyGenerationOptions.keyboardBeat(.init()).timeBasis == .beat)
        #expect(Template.AnyGenerationOptions.keyboardWall(.init()).timeBasis == .wall)
        #expect(Template.AnyGenerationOptions.standardBeat(.init()).timeBasis == .beat)
        #expect(Template.AnyGenerationOptions.standardWall(.init()).timeBasis == .wall)
    }
}
