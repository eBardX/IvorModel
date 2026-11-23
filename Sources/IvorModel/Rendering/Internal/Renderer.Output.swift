// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiNumbers

extension Renderer {

    // MARK: Internal Nested Types

    //
    // What rendering produces: each part's rendered notes and the fermata marks its notes'
    // fermatas became, both before the lead-in, and the lead-in itself (zero if nothing starts
    // before time zero).
    //
    internal struct Output {

        // MARK: Internal Instance Properties

        internal let fermataMarks: [[(time: Number, mark: PartMark<TimeType>)]]
        internal let leadIn: Number
        internal let notes: [[Note]]
    }
}
