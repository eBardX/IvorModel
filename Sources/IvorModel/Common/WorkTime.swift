// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

/// A moment in a work, in whichever time basis the work uses.
public enum WorkTime {

    /// A moment in a beat work, in whole notes.
    case beat(BeatTime)

    /// A moment in a wall work.
    case wall(WallTime)
}

// MARK: - Hashable

extension WorkTime: Hashable {
}

// MARK: - Sendable

extension WorkTime: Sendable {
}
