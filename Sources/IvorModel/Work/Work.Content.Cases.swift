// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Work.Content {

    // MARK: Public Nested Types

    /// A work’s content as one of six cases, one for each pitch notation and time basis, read
    /// through ``Work/Content/cases``.
    ///
    /// For code that handles each kind of content in its own way and wants the compiler to check
    /// that it handles them all. Code that works the same way for every kind is written once,
    /// over ``Work/Content/body``, instead.
    public enum Cases {
        /// Beat-time parts using absolute (frequency) pitch notation, with an associated tempo map,
        /// meter table and key table.
        case absoluteBeat([Part<BeatTime, Frequency>], TempoMap, MeterTable, KeyTable)

        /// Wall-time parts using absolute (frequency) pitch notation.
        case absoluteWall([Part<WallTime, Frequency>])

        /// Beat-time parts using keyboard (MIDI note number) pitch notation, with an associated tempo map,
        /// meter table and key table.
        case keyboardBeat([Part<BeatTime, NoteNumber>], TempoMap, MeterTable, KeyTable)

        /// Wall-time parts using keyboard (MIDI note number) pitch notation.
        case keyboardWall([Part<WallTime, NoteNumber>])

        /// Beat-time parts using standard (staff) pitch notation, with an associated tempo map,
        /// meter table and key table.
        case standardBeat([Part<BeatTime, Pitch>], TempoMap, MeterTable, KeyTable)

        /// Wall-time parts using standard (staff) pitch notation.
        case standardWall([Part<WallTime, Pitch>])
    }
}

// MARK: - Sendable

extension Work.Content.Cases: Sendable {
}
