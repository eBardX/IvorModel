// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiNumbers

struct ConversionFailureTests {
}

// MARK: -

extension ConversionFailureTests {
    @Test
    func error_canBeThrownAndCaught() {
        #expect(throws: ConversionFailure.self) {
            throw ConversionFailure()
        }
    }

    @Test
    func error_isAnError() {
        let error: any Error = ConversionFailure()

        #expect(error is ConversionFailure)
    }
}
