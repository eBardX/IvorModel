// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PartMarkTests {
}

// MARK: -

extension PartMarkTests {
    private typealias Mark = PartMark<BeatTime>

    @Test
    func codable_caesura() throws {
        #expect(try encodedJSON(Mark.caesura(nil)) == #"{"caesura":true}"#)

        let withPause = Mark.caesura(CaesuraExecution(pause: .seconds(positiveSeconds(1))))

        #expect(try codingRoundTrip(withPause) == withPause)
        #expect(try codingRoundTrip(Mark.caesura(nil)) == .caesura(nil))
    }

    @Test
    func codable_fermata() throws {
        let mark = Mark.fermata(Fermata(shape: .long), span: positiveBeats(1, 4))
        let json = try "{\"fermata\":[" + encodedJSON(Fermata<BeatTime>(shape: .long)) + "," + encodedJSON(positiveBeats(1, 4)) + "]}"

        #expect(try encodedJSON(mark) == json)
        #expect(try codingRoundTrip(mark) == mark)
    }

    @Test
    func codable_rejects() throws {
        let zeroSpan = try "{\"fermata\":[" + encodedJSON(Fermata<BeatTime>()) + "," + encodedJSON(beats(0)) + "]}"

        for json in [#"{"caesura":false}"#, #"{"breath":true}"#, #"{}"#, zeroSpan] {
            #expect(throws: DecodingError.self) {
                try decodeJSON(Mark.self, json)
            }
        }
    }

    @Test
    func scaled() {
        let fermata = Mark.fermata(Fermata(execution: FermataExecution(hold: .added(positiveBeats(1, 8)))),
                                   span: positiveBeats(1, 4))

        #expect(fermata.scaled(by: 2) == .fermata(Fermata(execution: FermataExecution(hold: .added(positiveBeats(1, 4)))),
                                                  span: positiveBeats(1, 2)))
        #expect(fermata.scaled(by: 0) == nil)

        let caesura = Mark.caesura(CaesuraExecution(pause: .added(positiveBeats(1, 8))))

        #expect(caesura.scaled(by: 2) == .caesura(CaesuraExecution(pause: .added(positiveBeats(1, 4)))))
        #expect(Mark.caesura(nil).scaled(by: 0) == .caesura(nil))
    }

    @Test
    func span() {
        #expect(Mark.caesura(nil).span == nil)
        #expect(Mark.fermata(Fermata(), span: positiveBeats(1, 4)).span == beats(frac(1, 4)))
    }

    @Test
    func withSpan() {
        #expect(Mark.fermata(Fermata(), span: positiveBeats(1, 4)).withSpan(positiveBeats(1)) == .fermata(Fermata(), span: positiveBeats(1)))
        #expect(Mark.caesura(nil).withSpan(positiveBeats(1)) == .caesura(nil))
    }
}
