// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiNumbers

extension Renderer {

    // MARK: Internal Nested Types

    //
    // A moment in one part: what a chord (the notes of a part sharing an attack) or a set of
    // notes ending together is keyed by.
    //
    internal struct Moment {

        // MARK: Internal Instance Properties

        internal let part: Int
        internal let time: Number
    }
}

// MARK: - Hashable

extension Renderer.Moment: Hashable {
}
