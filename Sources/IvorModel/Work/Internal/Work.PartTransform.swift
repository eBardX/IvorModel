// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

extension Work {

    // MARK: Internal Type Aliases

    //
    // Shorthand for a per-part transform closure, given the part and what the scope takes of
    // it, used only to keep `transform(_:resolution:kind:_:)`'s own signature below a
    // manageable line length.
    //
    internal typealias PartTransform<T: TimeProtocol, P: PitchProtocol> = (inout Part<T, P>, PartSelection) throws(Part<T, P>.Error) -> Void
}
