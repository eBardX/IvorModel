// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

struct TemplateVariantTests {
}

// MARK: -

extension TemplateVariantTests {
    @Test
    func codable() throws {
        let original = Template.Variant(isInverted: true,
                                        isRetrograde: true,
                                        timeFactor: Number(numerator: 1, denominator: 2),
                                        transposition: descending(.perfect5))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Template.Variant.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func hashable() {
        let variants: Set = [Template.Variant(isInverted: true, isRetrograde: false, timeFactor: nil, transposition: nil),
                             Template.Variant(isInverted: true, isRetrograde: false, timeFactor: nil, transposition: nil),
                             Template.Variant(isInverted: false, isRetrograde: true, timeFactor: nil, transposition: nil)]

        #expect(variants.count == 2)
    }

    @Test
    func init_storesValues() {
        let variant = Template.Variant(isInverted: false,
                                       isRetrograde: true,
                                       timeFactor: 2,
                                       transposition: ascending(.major3))

        #expect(!variant.isInverted)
        #expect(variant.isRetrograde)
        #expect(variant.timeFactor == 2)
        #expect(variant.transposition == ascending(.major3))
    }
}
