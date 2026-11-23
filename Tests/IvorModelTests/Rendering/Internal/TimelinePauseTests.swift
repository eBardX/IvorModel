// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct TimelinePauseTests {
}

// MARK: -

extension TimelinePauseTests {
    @Test
    func init_storesEveryField() {
        let pause = TimelinePause(length: frac(1, 2), seconds: 2, time: 1)

        #expect(pause.length == frac(1, 2))
        #expect(pause.seconds == 2)
        #expect(pause.time == 1)
    }
}
