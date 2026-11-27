// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Work {

    // MARK: Public Nested Types

    /// The body of beat-time content in one pitch notation: its parts, tempo map, meter table
    /// and key table.
    public struct BeatBody<PitchType: PitchProtocol> {

        // MARK: Public Initializers

        /// Creates a beat-time body.
        ///
        /// - Parameter parts:      The body’s parts, in score order. Defaults to none.
        /// - Parameter tempoMap:   The body’s tempo map. Defaults to an empty one.
        /// - Parameter meterTable: The body’s meter table. Defaults to an empty one.
        /// - Parameter keyTable:   The body’s key table. Defaults to an empty one.
        public init(parts: [Part<BeatTime, PitchType>] = [],
                    tempoMap: TempoMap = TempoMap(),
                    meterTable: MeterTable = MeterTable(),
                    keyTable: KeyTable = KeyTable()) {
            self.keyTable = keyTable
            self.meterTable = meterTable
            self.parts = parts
            self.tempoMap = tempoMap
        }

        // MARK: Public Instance Properties

        /// The body’s key table.
        public var keyTable: KeyTable

        /// The body’s meter table.
        public var meterTable: MeterTable

        /// The body’s parts, in score order.
        public var parts: [Part<BeatTime, PitchType>]

        /// The body’s tempo map.
        public var tempoMap: TempoMap
    }
}

// MARK: - BeatTimeBody

extension Work.BeatBody: Work.BeatTimeBody {

    // MARK: Public Type Properties

    /// The time basis of every beat-time body: ``TimeBasis/beat``.
    public static var timeBasis: TimeBasis {
        .beat
    }
}

// MARK: - Sendable

extension Work.BeatBody: Sendable {
}
