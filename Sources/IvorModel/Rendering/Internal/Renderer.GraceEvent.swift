// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiNumbers

extension Renderer {

    // MARK: Internal Nested Types

    //
    // One placed grace event: its span and pitches (one rendered note each).
    //
    internal struct GraceEvent {

        // MARK: Internal Initializers

        internal init(end: Number,
                      pitches: [PitchType],
                      start: Number) {
            self.end = end
            self.start = start
            self.pitches = pitches
        }

        // MARK: Internal Instance Properties

        internal let end: Number
        internal let start: Number

        internal var pitches: [PitchType]
    }
}
