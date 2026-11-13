// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension MeterTable {

    // MARK: Public Nested Types

    /// A beat time expressed as a bar, a beat within it, and an offset from that beat — the
    /// `bar:beat` a composer reads.
    ///
    /// For example, in one bar of 6/8 from time 0, the beat time 1/2 is bar 1, beat 2, offset 1/8
    /// of a beat 3/8 long: 1:2⅓.
    public struct Position {

        // MARK: Public Instance Properties

        /// The bar number: 0 for the pickup bar, and counting from 1 after it.
        public let bar: Int

        /// The beat number within the bar, counting from 1 following the bar’s pulse, or `nil` in
        /// a free bar. In the pickup bar, beats are numbered as the tail of a full bar.
        public let beat: Int?

        /// The full length of the beat, or `nil` in a free bar. In a short bar, the last beat may
        /// be cut off before this length.
        public let beatLength: BeatDuration?

        /// The distance from the start of the beat — or, in a free bar, from the start of the
        /// bar.
        public let offset: BeatDuration

        // MARK: Internal Initializers

        internal init(bar: Int,
                      beat: Int?,
                      offset: BeatDuration,
                      beatLength: BeatDuration?) {
            self.bar = bar
            self.beat = beat
            self.beatLength = beatLength
            self.offset = offset
        }
    }
}

// MARK: - Hashable

extension MeterTable.Position: Hashable {
}

// MARK: - Sendable

extension MeterTable.Position: Sendable {
}
