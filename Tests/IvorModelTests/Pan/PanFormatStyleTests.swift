// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct PanFormatStyleTests {
}

// MARK: -

extension PanFormatStyleTests {
    @Test
    func format() {
        let style = Pan.FormatStyle()
        let result = style.format(.center)

        #expect(!result.characters.isEmpty)
    }

    @Test
    func formatted() {
        let result = Pan.center.formatted()

        #expect(!result.characters.isEmpty)
    }

    @Test
    func locale() {
        let locale = Locale(identifier: "en_US")
        let style = Pan.FormatStyle(locale: locale)

        #expect(style.locale.identifier == "en_US")
    }
}
