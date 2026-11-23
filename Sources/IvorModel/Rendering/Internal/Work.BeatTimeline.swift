// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiNumbers

extension Work {

    // MARK: Internal Nested Types

    //
    // A beat work's content once its fermatas and caesuras are turned into time, and where each
    // fermata's span now starts.
    //
    internal struct BeatTimeline<PitchType: PitchProtocol> {

        // MARK: Internal Instance Properties

        internal let keyTable: KeyTable
        internal let meterTable: MeterTable
        internal let parts: [Part<BeatTime, PitchType>]
        internal let tempoMap: TempoMap
        internal let times: [Number]
    }
}
