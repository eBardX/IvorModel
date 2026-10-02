// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing

struct PartMetadataTests {
}

// MARK: -

extension PartMetadataTests {
    private typealias MetadataSB = Part<BeatTime, Pitch>.Metadata
    private typealias MetadataWF = Part<WallTime, Frequency>.Metadata

    @Test
    func assignment_blankAbbreviation_becomesNil() {
        var metadata = MetadataSB(abbreviation: "Vln.")

        metadata.abbreviation = " \t "

        #expect(metadata.abbreviation == nil)
    }

    @Test
    func assignment_normalizesAbbreviation() {
        var metadata = MetadataSB()

        metadata.abbreviation = " Vln.  1 "

        #expect(metadata.abbreviation == "Vln. 1")
    }

    @Test
    func codable_emptyWritesRemarks() throws {
        let data = try JSONEncoder().encode(MetadataSB())
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(Set(object.keys) == ["remarks"])
    }

    @Test
    func codable_missingRemarksIsError() {
        let data = Data(#"{"abbreviation":"Vln."}"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(MetadataSB.self, from: data)
        }
    }

    @Test
    func codable_normalizesAbbreviation() throws {
        let data = Data(#"{"abbreviation":"  Vln. \n 1 ","remarks":[]}"#.utf8)
        let decoded = try JSONDecoder().decode(MetadataSB.self, from: data)

        #expect(decoded.abbreviation == "Vln. 1")
    }

    @Test
    func codable_roundTrips() throws {
        let original = try MetadataSB(abbreviation: "Vln.",
                                      remarks: [#require(Remark(text: "Muted throughout."))])
        let decoded = try JSONDecoder().decode(MetadataSB.self, from: JSONEncoder().encode(original))

        #expect(decoded == original)
    }

    @Test
    func init_converting() throws {
        let original = try MetadataSB(abbreviation: "Vln.",
                                      remarks: [#require(Remark(text: "Muted throughout."))])
        let converted = MetadataWF(original)

        #expect(converted.abbreviation == original.abbreviation)
        #expect(converted.remarks == original.remarks)
    }

    @Test
    func init_defaults() {
        let metadata = MetadataSB()

        #expect(metadata.abbreviation == nil)
        #expect(metadata.remarks.isEmpty)
    }

    @Test
    func init_normalizesAbbreviation() {
        #expect(MetadataSB(abbreviation: " Vln.\t1 ").abbreviation == "Vln. 1")
        #expect(MetadataSB(abbreviation: "   ").abbreviation == nil)
    }
}
