// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiNumbers

// MARK: - RenderableTime

extension BeatTime: RenderableTime {

    // MARK: Internal Type Methods

    internal static func duration(fromNumber number: Number) -> BeatDuration? {
        BeatDuration(numberValue: number)
    }

    internal static func number(of duration: BeatDuration) -> Number {
        duration.numberValue
    }

    // MARK: Internal Initializers

    internal init?(number: Number) {
        self.init(numberValue: number)
    }

    // MARK: Internal Instance Properties

    internal var number: Number {
        numberValue
    }
}
