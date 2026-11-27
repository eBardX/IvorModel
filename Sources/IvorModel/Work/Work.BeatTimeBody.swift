// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension Work {

    // MARK: Public Nested Types

    /// The body of beat-time content, whatever its pitch notation: its parts, and the tempo map,
    /// meter table and key table that only beat time has.
    ///
    /// ``Work/BeatBody`` is the one conforming type. Code for every beat-time work casts a
    /// content’s body to `any Work.BeatTimeBody` and opens that, so it is written once for all
    /// three pitch notations; a failed cast means wall-time content.
    public protocol BeatTimeBody: Body where TimeType == BeatTime {

        // MARK: Instance Properties

        /// The body’s key table.
        var keyTable: KeyTable { get set }

        /// The body’s meter table.
        var meterTable: MeterTable { get set }

        /// The body’s tempo map.
        var tempoMap: TempoMap { get set }
    }
}

// MARK: -

extension Work.BeatTimeBody {

    // MARK: Public Instance Properties

    /// The beat-time range spanned by the notes of the body’s parts, or `nil` if there are none.
    public var beatTimeRange: ClosedRange<BeatTime>? {
        Work.aggregateTimeRange(of: parts)
    }
}
