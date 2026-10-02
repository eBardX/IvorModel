// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiTools

struct CreditRoleTests {
}

// MARK: -

extension CreditRoleTests {
    @Test
    func codable_unnormalizedIsError() {
        let data = Data(#"[" composer"]"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([Credit.Role].self, from: data)
        }
    }

    @Test
    func custom() throws {
        let role = try #require(Credit.Role(stringValue: "transcriber"))

        #expect(role.stringValue == "transcriber")
    }

    @Test
    func init_empty_returnsNil() {
        #expect(Credit.Role(stringValue: "") == nil)
    }

    @Test
    func init_unnormalized_returnsNil() {
        #expect(Credit.Role(stringValue: " composer") == nil)
        #expect(Credit.Role(stringValue: "composer ") == nil)
        #expect(Credit.Role(stringValue: "sound  designer") == nil)
        #expect(Credit.Role(stringValue: "sound\ndesigner") == nil)
    }

    @Test
    func standardRoles() {
        #expect(Credit.Role.arranger.stringValue == "arranger")
        #expect(Credit.Role.composer.stringValue == "composer")
        #expect(Credit.Role.lyricist.stringValue == "lyricist")
    }

    @Test
    func standardRoles_equalToStringValue() {
        #expect(Credit.Role(stringValue: "composer") == .composer)
    }
}
