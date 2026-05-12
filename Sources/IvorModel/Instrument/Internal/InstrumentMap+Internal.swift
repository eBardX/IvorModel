internal import XestiTools

extension InstrumentMap {

    // MARK: Internal Type Methods

    internal static func determineHasExtras(_ entries: [Entry]) -> Bool {
        entries.contains { $0.extras != nil }
    }

    // MARK: Internal Instance Methods

    internal func indexForInserting(time: TimeType) -> Int {
        entries.firstIndex { time < $0.time } ?? entries.endIndex
    }

    internal func indexMatching(time: TimeType,
                                instrument: Instrument,
                                extras: Extras?) -> Int? {
        entries.firstIndex {
            (time, instrument, extras) == ($0.time, $0.instrument, $0.extras)
        }
    }
}
