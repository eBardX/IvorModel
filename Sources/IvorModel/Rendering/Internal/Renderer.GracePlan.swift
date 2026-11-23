// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiNumbers

extension Renderer {

    // MARK: Internal Nested Types

    //
    // How a grace figure shares its time: `outside`, taken from the neighbor on its side (before
    // the beat, for a figure before; after the release, for a figure after), `inside`, taken from
    // the main note, and each event's length, in order, summing to the two.
    //
    internal struct GracePlan {

        // MARK: Internal Instance Properties

        internal let inside: Number
        internal let lengths: [Number]
        internal let outside: Number
    }
}
