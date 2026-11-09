// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct TemplateGenerationOptionsChainOptionsTests {
}

// MARK: -

extension TemplateGenerationOptionsChainOptionsTests {
    @Test
    func codable() throws {
        let original = StandardBeatOptions.ChainOptions(order: 2,
                                                        mixing: .blend(with: 1, weight: 0.25),
                                                        contrast: 1.5)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StandardBeatOptions.ChainOptions.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func hashable() {
        let options: Set = [StandardBeatOptions.ChainOptions(),
                            StandardBeatOptions.ChainOptions(),
                            StandardBeatOptions.ChainOptions(order: 2)]

        #expect(options.count == 2)
    }

    @Test
    func init_defaults() {
        let options = StandardBeatOptions.ChainOptions()

        #expect(options.contrast == 1)
        #expect(options.mixing == nil)
        #expect(options.order == 1)
    }

    @Test
    func topOrder_blendWithHigherOrder() {
        #expect(StandardBeatOptions.ChainOptions(order: 1, mixing: .blend(with: 3, weight: 0.5)).topOrder == 3)
    }

    @Test
    func topOrder_morphWithLowerOrder() {
        #expect(StandardBeatOptions.ChainOptions(order: 2, mixing: .morph(to: 0, over: 4, curve: .linear)).topOrder == 2)
    }

    @Test
    func topOrder_withoutMixing() {
        #expect(StandardBeatOptions.ChainOptions(order: 2).topOrder == 2)
    }

    @Test(arguments: [0, -1, Double.infinity, Double.nan])
    func validate_invalidContrast_throws(contrast: Double) {
        #expect(throws: Template.Error.invalidContrast) {
            try StandardBeatOptions.ChainOptions(contrast: contrast).validate(maximumOrder: 2)
        }
    }

    @Test
    func validate_invalidMixing_throws() {
        #expect(throws: Template.Error.invalidMixing) {
            try StandardBeatOptions.ChainOptions(mixing: .blend(with: 0, weight: 2)).validate(maximumOrder: 2)
        }
    }

    @Test(arguments: [-1, 3])
    func validate_orderOutOfRange_throws(order: Int) {
        #expect(throws: Template.Error.invalidOrder(2)) {
            try StandardBeatOptions.ChainOptions(order: order).validate(maximumOrder: 2)
        }
    }

    @Test
    func validate_valid_succeeds() throws {
        try StandardBeatOptions.ChainOptions(order: 0, mixing: .blend(with: 2, weight: 0.5), contrast: 2).validate(maximumOrder: 2)
    }
}
