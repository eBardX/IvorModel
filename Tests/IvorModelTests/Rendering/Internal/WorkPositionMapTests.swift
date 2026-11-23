// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkPositionMapTests {
}

// MARK: -

extension WorkPositionMapTests {
    @Test
    func positionMap_tellsAReleaseFromAnAttack() {
        let map: Work.PositionMap = { position, isRelease in
            TimelineOperation.insert(at: 1, length: 1).mapped(position, isRelease: isRelease)
        }

        #expect(map(1, false) == 2)
        #expect(map(1, true) == 1)
    }
}
