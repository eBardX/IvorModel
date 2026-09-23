// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiNumbers

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
    func format_showsBothAngles() {
        let style = Pan.FormatStyle(locale: Locale(identifier: "en_US"))
        let result = style.format(Pan(horizontal: -45, vertical: 30))

        #expect(String(result.characters) == "-45°H\u{00A0}30°V")
    }

    @Test
    func format_omitsZeroVertical() {
        let style = Pan.FormatStyle(locale: Locale(identifier: "en_US"))
        let result = style.format(Pan(horizontal: -45))

        #expect(String(result.characters) == "-45°H")
    }

    @Test
    func format_parsesAsPlain() {
        let pan = Pan(horizontal: -45, vertical: 30)
        let result = Pan.FormatStyle(locale: Locale(identifier: "en_US")).format(pan)

        #expect(Pan(plain: String(result.characters)) == pan)
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
