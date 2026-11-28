// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

extension Work {

    // MARK: Internal Nested Types

    //
    // One edit of one strand, as `Work`'s strand operations apply it.
    //
    internal enum StrandEdit {
        case giveOwnDynamicMap
        case giveOwnInstrumentTable
        case remove
        case removeOwnDynamicMap
        case removeOwnInstrumentTable
        case rename(String)
        case setExtras(Extras?)
        case shift(Int)
    }
}

// MARK: - Sendable

extension Work.StrandEdit: Sendable {
}
