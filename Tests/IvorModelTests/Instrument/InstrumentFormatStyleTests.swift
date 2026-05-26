// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct InstrumentFormatStyleTests {
}

// MARK: -

extension InstrumentFormatStyleTests {
    @Test
    func format() {
        let style = Instrument.FormatStyle()
        let result = style.format(.vanilla)

        #expect(String(result.characters) == "Vanilla")
    }

    @Test
    func formatted() {
        let result = Instrument.vanilla.formatted()

        #expect(String(result.characters) == "Vanilla")
    }

    @Test
    func locale() {
        let locale = Locale(identifier: "fr_FR")
        let style = Instrument.FormatStyle(locale: locale)

        #expect(style.locale.identifier == "fr_FR")
    }
}
