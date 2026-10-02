// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiTools

struct RightsNoticeScopeTests {
}

// MARK: -

extension RightsNoticeScopeTests {
    @Test
    func custom() throws {
        let scope = try #require(RightsNotice.Scope(stringValue: "recording"))

        #expect(scope.stringValue == "recording")
    }

    @Test
    func init_empty_returnsNil() {
        #expect(RightsNotice.Scope(stringValue: "") == nil)
    }

    @Test
    func init_unnormalized_returnsNil() {
        #expect(RightsNotice.Scope(stringValue: " music") == nil)
        #expect(RightsNotice.Scope(stringValue: "music\n") == nil)
        #expect(RightsNotice.Scope(stringValue: "sound\trecording") == nil)
    }

    @Test
    func standardScopes() {
        #expect(RightsNotice.Scope.arrangement.stringValue == "arrangement")
        #expect(RightsNotice.Scope.music.stringValue == "music")
        #expect(RightsNotice.Scope.transcription.stringValue == "transcription")
        #expect(RightsNotice.Scope.words.stringValue == "words")
    }
}
