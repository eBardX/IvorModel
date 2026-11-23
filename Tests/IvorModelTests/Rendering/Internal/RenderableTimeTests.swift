// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct RenderableTimeTests {
}

// MARK: -

extension RenderableTimeTests {
    @Test
    func initNumber_aNegativeNumberIsNoTimeForEveryConformer() {
        let types: [any RenderableTime.Type] = [BeatTime.self, WallTime.self]

        for type in types {
            let time = type.init(number: -1)

            #expect(time == nil)
        }
    }

    @Test
    func number_roundTripsForEveryConformer() {
        let types: [any RenderableTime.Type] = [BeatTime.self, WallTime.self]

        for type in types {
            let time = type.init(number: frac(3, 2))

            #expect(time?.number == frac(3, 2))
        }
    }
}
