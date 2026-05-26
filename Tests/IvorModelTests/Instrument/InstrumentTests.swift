// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct InstrumentTests {
}

// MARK: -

extension InstrumentTests {
    @Test
    func formatted() {
        let result = Instrument.vanilla.formatted()

        #expect(String(result.characters) == "Vanilla")
    }

    @Test
    func init_valid() {
        #expect(Instrument(stringValue: "Guitar") != nil)
        #expect(Instrument(stringValue: "Electric Piano") != nil)
    }

    @Test
    func init_invalid() {
        #expect(Instrument(stringValue: "") == nil)
    }

    @Test
    func stringValue() throws {
        let inst = try #require(Instrument(stringValue: "Flute"))

        #expect(inst.stringValue == "Flute")
    }

    @Test
    func vanilla() {
        #expect(Instrument.vanilla.stringValue == "Vanilla")
    }
}
