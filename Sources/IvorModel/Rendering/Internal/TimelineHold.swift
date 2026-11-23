// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiNumbers

//
// One fermata's hold, as the timeline reads it: where its span starts and how long it is, how
// much longer it lasts (in the work's own units and in seconds), whether its execution set the
// hold explicitly, and where it was written. Positions are in the work's own numbers.
//
internal struct TimelineHold {

    // MARK: Internal Instance Properties

    internal let extra: Number
    internal let extraSeconds: Number
    internal let isExplicit: Bool
    internal let noteID: NoteID?
    internal let part: Int
    internal let span: Number
    internal let time: Number
}

// MARK: - Sendable

extension TimelineHold: Sendable {
}
