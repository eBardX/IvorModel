// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct UniqueIDTests {
}

// MARK: -

extension UniqueIDTests {
    @Test
    func init_hasPrefixAndIsValid() {
        let workID = WorkID()

        #expect(workID.stringValue.hasPrefix(WorkID.validPrefix))
        #expect(workID.stringValue.count == 24)
        #expect(WorkID.isValid(workID.stringValue))
    }

    @Test
    func init_isUnique() {
        #expect(Set((0..<100).map { _ in NoteID() }).count == 100)
    }

    @Test
    func init_stringValue_invalid_isNil() {
        #expect(PartID(stringValue: "") == nil)
        #expect(PartID(stringValue: "P$short") == nil)
        #expect(PartID(stringValue: WorkID().stringValue) == nil)
    }

    @Test
    func init_stringValue_valid_roundTrips() throws {
        let original = TemplateID()
        let parsed = try #require(TemplateID(stringValue: original.stringValue))

        #expect(parsed == original)
    }

    @Test
    func isValid_requiresWholeMatch() {
        let stringValue = EntryID().stringValue

        #expect(EntryID.isValid(stringValue))
        #expect(!EntryID.isValid(stringValue + "x"))
        #expect(!EntryID.isValid(" " + stringValue))
    }

    @Test
    func validPrefix_isDistinctForEveryConformer() {
        let prefixes = [EntryID.validPrefix,
                        NoteID.validPrefix,
                        PartID.validPrefix,
                        RealizationID.validPrefix,
                        TemplateID.validPrefix,
                        WorkID.validPrefix]

        #expect(Set(prefixes).count == prefixes.count)
        #expect(prefixes.allSatisfy { $0.count == 2 })
    }

    @Test
    func validPrefix_matchesEveryConformersNewIDs() {
        #expect(EntryID().stringValue.hasPrefix(EntryID.validPrefix))
        #expect(NoteID().stringValue.hasPrefix(NoteID.validPrefix))
        #expect(PartID().stringValue.hasPrefix(PartID.validPrefix))
        #expect(RealizationID().stringValue.hasPrefix(RealizationID.validPrefix))
        #expect(TemplateID().stringValue.hasPrefix(TemplateID.validPrefix))
        #expect(WorkID().stringValue.hasPrefix(WorkID.validPrefix))
    }
}
