// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiNumbers

extension Renderer {

    // MARK: Internal Nested Types

    //
    // What makes tones one roll: their attack and their arpeggio group, anywhere in the work.
    //
    internal struct RollKey {

        // MARK: Internal Instance Properties

        internal let group: ArpeggioGroup
        internal let part: Int
        internal let time: Number
    }
}

// MARK: - Hashable

extension Renderer.RollKey: Hashable {
}
