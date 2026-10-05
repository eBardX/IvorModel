// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct WorkInfoTests {
}

// MARK: -

extension WorkInfoTests {
    @Test
    func assignment_normalizesTitles() {
        var info = Work.Info()

        info.title = "  Aubade \n"
        info.parentWorkTitle = "Suite  No. 1"
        info.subtitles = [" for  piano ", "   "]
        info.alternateTitles = ["Dawn\tSong"]

        #expect(info.title == "Aubade")
        #expect(info.parentWorkTitle == "Suite No. 1")
        #expect(info.subtitles == ["for piano"])
        #expect(info.alternateTitles == ["Dawn Song"])
    }

    @Test
    func assignment_blankDedication_becomesNil() {
        var info = Work.Info(dedication: "To my teacher")

        info.dedication = " \n\t "

        #expect(info.dedication == nil)
    }

    @Test
    func assignment_dedication_keepsLineBreaks() {
        var info = Work.Info()

        info.dedication = "  To my  teacher \n in memory  "

        #expect(info.dedication == "To my teacher\nin memory")
    }

    @Test
    func assignment_blankTitle_becomesNil() {
        var info = Work.Info(title: "Aubade", parentWorkTitle: "Suite")

        info.title = "   "
        info.parentWorkTitle = "\n"

        #expect(info.title == nil)
        #expect(info.parentWorkTitle == nil)
    }

    @Test
    func append_blankSubtitle_isNoOp() {
        var info = Work.Info(subtitles: ["Op. 1"])

        info.subtitles.append("  ")
        info.alternateTitles.append("\t")

        #expect(info.subtitles == ["Op. 1"])
        #expect(info.alternateTitles.isEmpty)
    }

    @Test
    func codable_emptyWritesEveryArray() throws {
        let data = try JSONEncoder().encode(Work.Info())
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(Set(object.keys) == ["alternateTitles", "credits", "remarks", "rights", "subtitles"])
    }

    @Test
    func codable_missingArrayIsError() throws {
        let data = try JSONEncoder().encode(Work.Info())
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        object["credits"] = nil

        let badData = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Work.Info.self, from: badData)
        }
    }

    @Test
    func codable_normalizesTitles() throws {
        let json = #"""
            {"title":"  Aubade ","subtitles":[" a  b ",""],"alternateTitles":["  "],
             "parentWorkTitle":" ","credits":[],"rights":[],"remarks":[]}
            """#
        let decoded = try JSONDecoder().decode(Work.Info.self, from: Data(json.utf8))

        #expect(decoded.title == "Aubade")
        #expect(decoded.subtitles == ["a b"])
        #expect(decoded.alternateTitles.isEmpty)
        #expect(decoded.parentWorkTitle == nil)
    }

    @Test
    func codable_normalizesDedication() throws {
        let json = #"""
            {"dedication":" To  my\n teacher ","subtitles":[],"alternateTitles":[],
             "credits":[],"rights":[],"remarks":[]}
            """#
        let decoded = try JSONDecoder().decode(Work.Info.self, from: Data(json.utf8))

        #expect(decoded.dedication == "To my\nteacher")
    }

    @Test
    func codable_roundTrips() throws {
        let original = makeWorkInfo()
        let decoded = try JSONDecoder().decode(Work.Info.self, from: JSONEncoder().encode(original))

        #expect(decoded == original)
    }

    @Test
    func composers() throws {
        let info = try Work.Info(credits: [#require(Credit(name: "A", role: .composer)),
                                           #require(Credit(name: "B", role: .lyricist)),
                                           #require(Credit(name: "C")),
                                           #require(Credit(name: "D", role: .composer))])

        #expect(info.composers == ["A", "D"])
    }

    @Test
    func equality() {
        let info1 = makeWorkInfo()
        let info2 = makeWorkInfo()

        #expect(info1 == info2)
        #expect(info1 != Work.Info())
    }

    @Test
    func init_defaults() {
        let info = Work.Info()

        #expect(info.title == nil)
        #expect(info.subtitles.isEmpty)
        #expect(info.alternateTitles.isEmpty)
        #expect(info.parentWorkTitle == nil)
        #expect(info.dedication == nil)
        #expect(info.credits.isEmpty)
        #expect(info.rights.isEmpty)
        #expect(info.remarks.isEmpty)
    }

    @Test
    func init_normalizesTitles() {
        let info = Work.Info(title: " Aubade  in  C ",
                             subtitles: ["", " for\npiano "],
                             alternateTitles: [" Dawn ", "  "],
                             parentWorkTitle: "   ",
                             dedication: " To  my\n\n teacher ")

        #expect(info.title == "Aubade in C")
        #expect(info.subtitles == ["for piano"])
        #expect(info.alternateTitles == ["Dawn"])
        #expect(info.parentWorkTitle == nil)
        #expect(info.dedication == "To my\n\nteacher")
    }
}
