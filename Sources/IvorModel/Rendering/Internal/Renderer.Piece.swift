// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiNumbers

extension Renderer {

    // MARK: Internal Nested Types

    //
    // One stretch of a main note once its ornament is rendered: the main note itself
    // (`partner == nil`), or its partner's pitches.
    //
    internal struct Piece {

        // MARK: Internal Initializers

        internal init(end: Number,
                      partner: [PitchType]?,
                      start: Number) {
            self.partner = partner
            self.end = end
            self.start = start
        }

        // MARK: Internal Instance Properties

        internal let partner: [PitchType]?

        internal var end: Number
        internal var start: Number
    }
}
