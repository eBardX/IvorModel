// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiNumbers

struct NumberRepresentableValidatedTests {
}

// MARK: -

extension NumberRepresentableValidatedTests {
    @Test
    func initValidatingFrom_aNonNumberThrows() {
        #expect(throws: DecodingError.self) {
            try decodeJSON(Proportion.self, "true")
        }
    }

    @Test
    func initValidatingFrom_anOutOfRangeValueThrowsDataCorrupted() {
        do {
            _ = try decodeJSON(Proportion.self, #""2""#)

            Issue.record("Decoded an out-of-range proportion")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription.contains("Proportion"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func initValidatingFrom_eachValidatedType() throws {
        #expect(try decodeJSON(FermataStretch.self, #""2""#) == fermataStretch(2))
        #expect(try decodeJSON(NotesPerSecond.self, #""12""#) == notesPerSecond(12))
        #expect(try decodeJSON(Proportion.self, #""1/2""#) == proportion(1, 2))
    }

    @Test
    func initValidatingFrom_zeroThrowsForEachValidatedType() {
        #expect(throws: DecodingError.self) { try decodeJSON(FermataStretch.self, #""0""#) }
        #expect(throws: DecodingError.self) { try decodeJSON(NotesPerSecond.self, #""0""#) }
        #expect(throws: DecodingError.self) { try decodeJSON(Proportion.self, #""0""#) }
    }
}
