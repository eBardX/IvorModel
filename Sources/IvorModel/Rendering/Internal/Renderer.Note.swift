// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiNumbers
internal import XestiTools

extension Renderer {

    // MARK: Internal Nested Types

    //
    // One rendered note, placed in the work's own numbers. Its start can be before zero until
    // the lead-in moves everything later.
    //
    internal struct Note {

        // MARK: Internal Instance Properties

        internal let end: Number
        internal let endPitch: PitchType
        internal let extras: Extras?
        internal let start: Number
        internal let startPitch: PitchType
    }
}
