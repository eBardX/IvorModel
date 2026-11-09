// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

struct TemplateSourceTests {
}

// MARK: -

extension TemplateSourceTests {
    @Test
    func codable() throws {
        let original = Template.Source(workID: WorkID(), workName: "Work", partID: PartID(), partName: "Part")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Template.Source.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func hashable() {
        let workID = WorkID()
        let partID = PartID()
        let sources: Set = [Template.Source(workID: workID, workName: "W", partID: partID, partName: "P"),
                            Template.Source(workID: workID, workName: "W", partID: partID, partName: "P"),
                            Template.Source(workID: workID, workName: "W", partID: PartID(), partName: "P")]

        #expect(sources.count == 2)
    }

    @Test
    func init_storesValues() {
        let workID = WorkID()
        let partID = PartID()
        let source = Template.Source(workID: workID, workName: "Work", partID: partID, partName: "Part")

        #expect(source.partID == partID)
        #expect(source.partName == "Part")
        #expect(source.workID == workID)
        #expect(source.workName == "Work")
    }

    @Test
    func initWorkIndex_outOfRange_isNil() {
        let work = makeStandardBeatWork(Fixtures.threeNoteMelody)

        #expect(Template.Source(work: work, index: 1) == nil)
        #expect(Template.Source(work: work, index: -1) == nil)
    }

    @Test
    func initWorkIndex_validIndex() throws {
        let work = makeNamedStandardBeatWork("Tune", Fixtures.threeNoteMelody)
        let source = try #require(Template.Source(work: work, index: 0))

        #expect(source.partID == work.partIDs[0])
        #expect(source.partName == "Piano")
        #expect(source.workID == work.workID)
        #expect(source.workName == "Tune")
    }
}
