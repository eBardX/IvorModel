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
        let original = Template.Source(workID: WorkID(),
                                       workName: "Work",
                                       partID: PartID(),
                                       partName: "Part",
                                       strands: [Template.SourceStrand(strandID: StrandID(), name: "RH")],
                                       isNoteSelection: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Template.Source.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func hashable() {
        let workID = WorkID()
        let partID = PartID()
        let sources: Set = [Template.Source(workID: workID, workName: "W", partID: partID, partName: "P", strands: [], isNoteSelection: false),
                            Template.Source(workID: workID, workName: "W", partID: partID, partName: "P", strands: [], isNoteSelection: false),
                            Template.Source(workID: workID, workName: "W", partID: PartID(), partName: "P", strands: [], isNoteSelection: false)]

        #expect(sources.count == 2)
    }

    @Test
    func init_storesValues() {
        let workID = WorkID()
        let partID = PartID()
        let source = Template.Source(workID: workID, workName: "Work", partID: partID, partName: "Part", strands: [], isNoteSelection: false)

        #expect(source.partID == partID)
        #expect(source.partName == "Part")
        #expect(source.workID == workID)
        #expect(source.workName == "Work")
    }

    @Test
    func initWorkSource_missingPart_isNil() {
        let work = makeStandardBeatWork(Fixtures.threeNoteMelody)

        #expect(Template.Source(work: work, source: Template.SourceScope(partID: PartID(), selection: .whole)) == nil)
    }

    @Test
    func initWorkSource_wholePart() throws {
        let work = makeNamedStandardBeatWork("Tune", Fixtures.threeNoteMelody)
        let partID = work.partIDs[0]
        let source = try #require(Template.Source(work: work, source: Template.SourceScope(partID: partID, selection: .whole)))
        let strandID = try #require(work.part(partID, as: Part<BeatTime, Pitch>.self)?.strandIDs.first)

        #expect(source.partID == partID)
        #expect(source.partName == "Piano")
        #expect(source.strands == [Template.SourceStrand(strandID: strandID, name: "")])
        #expect(!source.isNoteSelection)
        #expect(source.workID == work.workID)
        #expect(source.workName == "Tune")
    }
}
