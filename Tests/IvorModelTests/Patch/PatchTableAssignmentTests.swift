// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct PatchTableAssignmentTests {
}

// MARK: -

extension PatchTableAssignmentTests {
    @Test
    func codable_rejectsOutOfRangeChannel() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PatchTable.Assignment.self,
                                     from: Data(#"{"patch":{"generalMIDI1":{"program":1}},"channel":17}"#.utf8))
        }
    }

    @Test(arguments: [nil, 3])
    func codable_roundTrip(channel: Int?) throws {
        let original = try #require(PatchTable.Assignment(patch: makeOrganPatch(), channel: channel))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PatchTable.Assignment.self, from: data)

        #expect(decoded == original)
    }

    @Test(arguments: [0, 17])
    func init_rejectsOutOfRangeChannel(channel: Int) throws {
        #expect(try PatchTable.Assignment(patch: makeOrganPatch(), channel: channel) == nil)
    }

    @Test
    func init_withoutChannel() throws {
        let assignment = try #require(PatchTable.Assignment(patch: makeOrganPatch()))

        #expect(assignment.channel == nil)
        #expect(try assignment.patch == makeOrganPatch())
    }
}
