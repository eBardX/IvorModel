// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

extension Work {

    // MARK: Internal Type Aliases

    //
    // Shorthand for a per-part transform closure, used only to keep `transformed(...)`'s own
    // signature below a manageable line length.
    //
    internal typealias PartTransform<T: TimeProtocol, P: PitchProtocol> = (inout Part<T, P>) throws(Part<T, P>.Error) -> Void
}
