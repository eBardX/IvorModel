// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct RightsNoticeTests {
}

// MARK: -

extension RightsNoticeTests {
    @Test
    func codable_emptyTextIsError() throws {
        let data = Data(#"{"text":" \r\n "}"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RightsNotice.self, from: data)
        }
    }

    @Test
    func codable_missingScopeDecodesAsNil() throws {
        let data = Data(#"{"text":"© 1998 Acme"}"#.utf8)
        let decoded = try JSONDecoder().decode(RightsNotice.self, from: data)

        #expect(decoded.scope == nil)
    }

    @Test
    func codable_nilScopeIsOmitted() throws {
        let notice = try #require(RightsNotice(text: "© 1998 Acme"))
        let data = try JSONEncoder().encode(notice)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["scope"] == nil)
    }

    @Test
    func codable_normalizesText() throws {
        let data = Data(#"{"text":"  © 1998  Acme \r\n\r\n\r\nAll rights reserved\n"}"#.utf8)
        let decoded = try JSONDecoder().decode(RightsNotice.self, from: data)

        #expect(decoded.text == "© 1998 Acme\n\nAll rights reserved")
    }

    @Test
    func codable_roundTrips() throws {
        let original = try #require(RightsNotice(text: "© 2001 J. Smith\nArr. © 2010",
                                                 scope: .transcription))
        let decoded = try JSONDecoder().decode(RightsNotice.self, from: JSONEncoder().encode(original))

        #expect(decoded == original)
    }

    @Test
    func init_emptyText_returnsNil() {
        #expect(RightsNotice(text: "") == nil)
        #expect(RightsNotice(text: "\n\n  \n") == nil)
    }

    @Test
    func init_normalizesTextKeepingLineBreaks() throws {
        let notice = try #require(RightsNotice(text: "\n  Music © 1998  Acme \r\n Words © 1999 Beta\n"))

        #expect(notice.text == "Music © 1998 Acme\nWords © 1999 Beta")
    }

    @Test
    func init_scope() throws {
        let notice = try #require(RightsNotice(text: "© 1998 Acme", scope: .words))

        #expect(notice.scope == .words)
    }

    @Test
    func init_scopeDefaultsToNil() throws {
        let notice = try #require(RightsNotice(text: "Public domain"))

        #expect(notice.scope == nil)
    }
}
