// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorSMPTE
import Testing
import XestiNumbers

struct SMPTEExactSecondsIvorTests {
}

// MARK: -

extension SMPTEExactSecondsIvorTests {
    @Test
    func microseconds() {
        #expect(SMPTEExactSeconds.zero.microseconds == 0)
        #expect(SMPTEExactSeconds(90).microseconds == 90_000_000)
        #expect(SMPTEExactSeconds(Number(numerator: 1, denominator: 3_000_000)).microseconds == 0)
        #expect(SMPTEExactSeconds(Number(numerator: 2, denominator: 3_000_000)).microseconds == 1)
        #expect(SMPTEExactSeconds(Number(numerator: 1_001, denominator: 30_000)).microseconds == 33_367)
    }
}
