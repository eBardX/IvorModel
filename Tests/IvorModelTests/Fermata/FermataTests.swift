// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct FermataTests {
}

// MARK: -

extension FermataTests {
    @Test
    func codable_rejectsUnknownShape() {
        #expect(throws: DecodingError.self) {
            try decodeJSON(Fermata<BeatTime>.self, #"{"shape":"inverted"}"#)
        }
    }

    @Test
    func codable_roundTrip() throws {
        let fermata = Fermata<BeatTime>(shape: .long,
                                        execution: FermataExecution(hold: .stretch(FermataStretch(3))))

        #expect(try codingRoundTrip(fermata) == fermata)
        #expect(try encodedJSON(Fermata<BeatTime>()) == #"{"shape":"normal"}"#)
    }

    @Test
    func hashable() {
        #expect(Set([Fermata<BeatTime>(), Fermata<BeatTime>(), Fermata<BeatTime>(shape: .short)]).count == 2)
    }

    @Test
    func init_defaultsToANormalSignWithNoExecution() {
        #expect(Fermata<BeatTime>().shape == .normal)
        #expect(Fermata<BeatTime>().execution == nil)
    }

    @Test
    func scaled() {
        let fermata = Fermata<BeatTime>(execution: FermataExecution(hold: .added(positiveBeats(1, 4))))

        #expect(fermata.scaled(by: 2) == Fermata(execution: FermataExecution(hold: .added(positiveBeats(1, 2)))))
        #expect(fermata.scaled(by: 0) == nil)
        #expect(Fermata<BeatTime>(shape: .short).scaled(by: 0) == Fermata(shape: .short))
    }
}
