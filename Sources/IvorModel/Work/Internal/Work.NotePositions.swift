// © 2026 John Gary Pusey (see LICENSE.md)

extension Work {

    // MARK: Internal Nested Types

    //
    // Where a note's pitches sit in the list a pitch-notation conversion converts in one batch:
    // its grace figure before it, its start and end pitches, its ornament's written partner
    // pitches, and its grace figure after it.
    //
    internal struct NotePositions {

        // MARK: Internal Instance Properties

        internal var after: Range<Int>
        internal var before: Range<Int>
        internal var end: Int
        internal var partner: Range<Int>
        internal var start: Int
    }
}
