// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiNumbers

//
// A time type rendering can do signed arithmetic with: rendered notes can start before time zero
// (a grace figure before the first beat, a chord rolled into it) until the lead-in moves them
// later, and `TimeProtocol` has no negative times. So rendering works in plain numbers — whole
// notes for beat time, seconds for wall time — and turns them back into times at the end.
//
internal protocol RenderableTime: TimeProtocol {

    // MARK: Internal Type Methods

    static func duration(fromNumber number: Number) -> DurationType?

    static func number(of duration: DurationType) -> Number

    // MARK: Internal Initializers

    init?(number: Number)

    // MARK: Internal Instance Properties

    var number: Number { get }
}
