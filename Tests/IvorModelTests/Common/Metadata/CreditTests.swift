// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct CreditTests {
}

// MARK: -

extension CreditTests {
    @Test
    func codable_emptyNameIsError() throws {
        let data = Data(#"{"name":"  \n "}"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Credit.self, from: data)
        }
    }

    @Test
    func codable_missingRoleDecodesAsNil() throws {
        let data = Data(#"{"name":"Trad."}"#.utf8)
        let decoded = try JSONDecoder().decode(Credit.self, from: data)

        #expect(decoded.name == "Trad.")
        #expect(decoded.role == nil)
    }

    @Test
    func codable_nilRoleIsOmitted() throws {
        let credit = try #require(Credit(name: "Trad."))
        let data = try JSONEncoder().encode(credit)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["role"] == nil)
    }

    @Test
    func codable_normalizesName() throws {
        let data = Data(#"{"name":" J. S.\t Bach ","role":"composer"}"#.utf8)
        let decoded = try JSONDecoder().decode(Credit.self, from: data)

        #expect(decoded.name == "J. S. Bach")
        #expect(decoded.role == .composer)
    }

    @Test
    func codable_roundTrips() throws {
        let original = try #require(Credit(name: "J. S. Bach", role: .composer))
        let decoded = try JSONDecoder().decode(Credit.self, from: JSONEncoder().encode(original))

        #expect(decoded == original)
    }

    @Test
    func equality_afterNormalization() {
        #expect(Credit(name: "J. S. Bach") == Credit(name: "J. S.  Bach "))
    }

    @Test
    func init_emptyName_returnsNil() {
        #expect(Credit(name: "") == nil)
        #expect(Credit(name: " \t\n ") == nil)
    }

    @Test
    func init_normalizesName() throws {
        let credit = try #require(Credit(name: "  J. S.\n  Bach  "))

        #expect(credit.name == "J. S. Bach")
    }

    @Test
    func init_role() throws {
        let credit = try #require(Credit(name: "J. Smith", role: .arranger))

        #expect(credit.role == .arranger)
    }

    @Test
    func init_roleDefaultsToNil() throws {
        let credit = try #require(Credit(name: "J. Smith"))

        #expect(credit.role == nil)
    }
}
