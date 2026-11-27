// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Work {

    // MARK: Public Nested Types

    /// The body of wall-time content in one pitch notation: its parts.
    public struct WallBody<PitchType: PitchProtocol> {

        // MARK: Public Initializers

        /// Creates a wall-time body.
        ///
        /// - Parameter parts:  The body’s parts, in score order. Defaults to none.
        public init(parts: [Part<WallTime, PitchType>] = []) {
            self.parts = parts
        }

        // MARK: Public Instance Properties

        /// The body’s parts, in score order.
        public var parts: [Part<WallTime, PitchType>]
    }
}

// MARK: - WallTimeBody

extension Work.WallBody: Work.WallTimeBody {

    // MARK: Public Type Properties

    /// The time basis of every wall-time body: ``TimeBasis/wall``.
    public static var timeBasis: TimeBasis {
        .wall
    }
}

// MARK: - Sendable

extension Work.WallBody: Sendable {
}
