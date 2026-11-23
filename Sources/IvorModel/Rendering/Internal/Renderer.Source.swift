// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiNumbers
internal import XestiTools

extension Renderer {

    // MARK: Internal Nested Types

    //
    // One written note, as rendering reads it: its part, its written attack and release (in the
    // work's own numbers), its pitches, extras and ornamentation.
    //
    internal struct Source {

        // MARK: Internal Instance Properties

        internal let attack: Number
        internal let endPitch: PitchType
        internal let extras: Extras?
        internal let ornamentation: NoteTable<TimeType, PitchType>.Ornamentation?
        internal let part: Int
        internal let release: Number
        internal let startPitch: PitchType
    }
}

// MARK: -

extension Renderer.Source {

    // MARK: Internal Instance Properties

    internal var duration: Number {
        release - attack
    }
}
