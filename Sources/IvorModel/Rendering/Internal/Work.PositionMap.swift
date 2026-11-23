// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiNumbers

extension Work {

    // MARK: Internal Type Aliases

    //
    // Where a position (in the work's own numbers) lands once time is inserted: an attack or an
    // entry's time, or (`true`) a release, which stays put at an insertion's moment.
    //
    internal typealias PositionMap = (Number, Bool) -> Number
}
