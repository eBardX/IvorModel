// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct DynamicFormatStyleTests {
}

// MARK: -

extension DynamicFormatStyleTests {
    @Test
    func format() {
        let style = Dynamic.FormatStyle()
        let result = style.format(.mf)

        #expect(!result.characters.isEmpty)
    }

    @Test
    func formatted() {
        let result = Dynamic.mf.formatted()

        #expect(!result.characters.isEmpty)
    }

    @Test
    func locale() {
        let locale = Locale(identifier: "en_US")
        let style = Dynamic.FormatStyle(locale: locale)

        #expect(style.locale.identifier == "en_US")
    }
}
