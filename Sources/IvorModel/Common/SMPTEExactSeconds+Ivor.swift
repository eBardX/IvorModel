// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorSMPTE

private import XestiNumbers

extension SMPTEExactSeconds {

    // MARK: Internal Instance Properties

    // The number of seconds as a whole number of microseconds, rounded to the
    // nearest one — the resolution of `WallTime` and `WallDuration`.
    internal var microseconds: UInt {
        round(numberValue * 1_000_000).uintValue
    }
}
