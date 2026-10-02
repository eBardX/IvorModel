// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct RemarkTests {
}

// MARK: -

extension RemarkTests {
    @Test
    func codable_emptyTextIsError() throws {
        let data = Data(#"{"text":"","label":"history"}"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Remark.self, from: data)
        }
    }

    @Test
    func codable_nilLabelIsOmitted() throws {
        let remark = try #require(Remark(text: "Learned from a fiddler"))
        let data = try JSONEncoder().encode(remark)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["label"] == nil)
    }

    @Test
    func codable_normalizesTextAndLabel() throws {
        let data = Data(#"{"text":" Line  1 \n\n\n Line 2 ","label":"  "}"#.utf8)
        let decoded = try JSONDecoder().decode(Remark.self, from: data)

        #expect(decoded.text == "Line 1\n\nLine 2")
        #expect(decoded.label == nil)
    }

    @Test
    func codable_roundTrips() throws {
        let original = try #require(Remark(text: "Collected in 1902.\n\nSee also No. 7.",
                                           label: "history"))
        let decoded = try JSONDecoder().decode(Remark.self, from: JSONEncoder().encode(original))

        #expect(decoded == original)
    }

    @Test
    func init_blankLabel_becomesNil() throws {
        let remark = try #require(Remark(text: "Note", label: " \t "))

        #expect(remark.label == nil)
    }

    @Test
    func init_emptyText_returnsNil() {
        #expect(Remark(text: "") == nil)
        #expect(Remark(text: " \n\t ", label: "history") == nil)
    }

    @Test
    func init_labelDefaultsToNil() throws {
        let remark = try #require(Remark(text: "Note"))

        #expect(remark.label == nil)
    }

    @Test
    func init_normalizesLabelToSingleLine() throws {
        let remark = try #require(Remark(text: "Note", label: " source\n notes "))

        #expect(remark.label == "source notes")
    }

    @Test
    func init_normalizesTextKeepingLineBreaks() throws {
        let remark = try #require(Remark(text: "  First   line \r\n  \n \nSecond\tline\n"))

        #expect(remark.text == "First line\n\nSecond line")
    }
}
