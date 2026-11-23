// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct CaseCodingKeyTests {
}

// MARK: -

extension CaseCodingKeyTests {
    @Test
    func init_stringOnly() {
        #expect(CaseCodingKey(stringValue: "share")?.stringValue == "share")
        #expect(CaseCodingKey(intValue: 1) == nil)
        #expect(CaseCodingKey("share").intValue == nil)
    }
}
