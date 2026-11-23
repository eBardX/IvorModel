// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiNumbers

//
// Time inserted at a moment, during which nothing new starts: a caesura, or the pause after a
// fermata. Its length is in the work's own units and in seconds.
//
internal struct TimelinePause {

    // MARK: Internal Instance Properties

    internal let length: Number
    internal let seconds: Number
    internal let time: Number
}

// MARK: - Sendable

extension TimelinePause: Sendable {
}
