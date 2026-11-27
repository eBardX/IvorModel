// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension Work {

    // MARK: Public Nested Types

    /// The body of wall-time content, whatever its pitch notation: its parts.
    ///
    /// ``Work/WallBody`` is the one conforming type. Code for every wall-time work casts a
    /// content’s body to `any Work.WallTimeBody` and opens that, so it is written once for all
    /// three pitch notations; a failed cast means beat-time content.
    public protocol WallTimeBody: Body where TimeType == WallTime {
    }
}

// MARK: -

extension Work.WallTimeBody {

    // MARK: Public Instance Properties

    /// The wall-time range spanned by the notes of the body’s parts, or `nil` if there are none.
    public var wallTimeRange: ClosedRange<WallTime>? {
        Work.aggregateTimeRange(of: parts)
    }
}
