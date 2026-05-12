@testable import IvorModel
import Testing

struct InstrumentTests {
}

// MARK: -

extension InstrumentTests {
    @Test
    func init_valid() {
        #expect(Instrument(stringValue: "Guitar") != nil)
        #expect(Instrument(stringValue: "Electric Piano") != nil)
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
