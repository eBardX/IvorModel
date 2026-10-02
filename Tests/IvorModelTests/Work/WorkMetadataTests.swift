// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct WorkMetadataTests {
}

// MARK: -

extension WorkMetadataTests {
    @Test
    func assignment_normalizesTitles() {
        var metadata = Work.Metadata()

        metadata.title = "  Aubade \n"
        metadata.parentWorkTitle = "Suite  No. 1"
        metadata.subtitles = [" for  piano ", "   "]
        metadata.alternateTitles = ["Dawn\tSong"]

        #expect(metadata.title == "Aubade")
        #expect(metadata.parentWorkTitle == "Suite No. 1")
        #expect(metadata.subtitles == ["for piano"])
        #expect(metadata.alternateTitles == ["Dawn Song"])
    }

    @Test
    func assignment_blankTitle_becomesNil() {
        var metadata = Work.Metadata(title: "Aubade", parentWorkTitle: "Suite")

        metadata.title = "   "
        metadata.parentWorkTitle = "\n"

        #expect(metadata.title == nil)
        #expect(metadata.parentWorkTitle == nil)
    }

    @Test
    func append_blankSubtitle_isNoOp() {
        var metadata = Work.Metadata(subtitles: ["Op. 1"])

        metadata.subtitles.append("  ")
        metadata.alternateTitles.append("\t")

        #expect(metadata.subtitles == ["Op. 1"])
        #expect(metadata.alternateTitles.isEmpty)
    }

    @Test
    func codable_emptyWritesEveryArray() throws {
        let data = try JSONEncoder().encode(Work.Metadata())
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(Set(object.keys) == ["alternateTitles", "credits", "remarks", "rights", "subtitles"])
    }

    @Test
    func codable_missingArrayIsError() throws {
        let data = try JSONEncoder().encode(Work.Metadata())
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        object["credits"] = nil

        let badData = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Work.Metadata.self, from: badData)
        }
    }

    @Test
    func codable_normalizesTitles() throws {
        let json = #"""
            {"title":"  Aubade ","subtitles":[" a  b ",""],"alternateTitles":["  "],
             "parentWorkTitle":" ","credits":[],"rights":[],"remarks":[]}
            """#
        let decoded = try JSONDecoder().decode(Work.Metadata.self, from: Data(json.utf8))

        #expect(decoded.title == "Aubade")
        #expect(decoded.subtitles == ["a b"])
        #expect(decoded.alternateTitles.isEmpty)
        #expect(decoded.parentWorkTitle == nil)
    }

    @Test
    func codable_roundTrips() throws {
        let original = makeWorkMetadata()
        let decoded = try JSONDecoder().decode(Work.Metadata.self, from: JSONEncoder().encode(original))

        #expect(decoded == original)
    }

    @Test
    func composers() throws {
        let metadata = try Work.Metadata(credits: [#require(Credit(name: "A", role: .composer)),
                                                   #require(Credit(name: "B", role: .lyricist)),
                                                   #require(Credit(name: "C")),
                                                   #require(Credit(name: "D", role: .composer))])

        #expect(metadata.composers == ["A", "D"])
    }

    @Test
    func equality() {
        let metadata1 = makeWorkMetadata()
        let metadata2 = makeWorkMetadata()

        #expect(metadata1 == metadata2)
        #expect(metadata1 != Work.Metadata())
    }

    @Test
    func init_defaults() {
        let metadata = Work.Metadata()

        #expect(metadata.title == nil)
        #expect(metadata.subtitles.isEmpty)
        #expect(metadata.alternateTitles.isEmpty)
        #expect(metadata.parentWorkTitle == nil)
        #expect(metadata.credits.isEmpty)
        #expect(metadata.rights.isEmpty)
        #expect(metadata.remarks.isEmpty)
    }

    @Test
    func init_normalizesTitles() {
        let metadata = Work.Metadata(title: " Aubade  in  C ",
                                     subtitles: ["", " for\npiano "],
                                     alternateTitles: [" Dawn ", "  "],
                                     parentWorkTitle: "   ")

        #expect(metadata.title == "Aubade in C")
        #expect(metadata.subtitles == ["for piano"])
        #expect(metadata.alternateTitles == ["Dawn"])
        #expect(metadata.parentWorkTitle == nil)
    }
}
