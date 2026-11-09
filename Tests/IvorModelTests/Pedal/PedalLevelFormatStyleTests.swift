// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct PedalLevelFormatStyleTests {
}

// MARK: -

extension PedalLevelFormatStyleTests {
    @Test
    func format() {
        let style = Pedal.Level.FormatStyle()
        let result = style.format(.on)

        #expect(!result.characters.isEmpty)
    }

    @Test
    func formatted() {
        let result = Pedal.Level.off.formatted()

        #expect(!result.characters.isEmpty)
    }

    @Test
    func locale() {
        let locale = Locale(identifier: "en_US")
        let style = Pedal.Level.FormatStyle(locale: locale)

        #expect(style.locale.identifier == "en_US")
    }
}
