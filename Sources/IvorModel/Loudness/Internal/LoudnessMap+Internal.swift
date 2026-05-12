internal import XestiTools

extension LoudnessMap {

    // MARK: Internal Type Methods

    internal static func determineHasExtras(_ entries: [Entry]) -> Bool {
        entries.contains { $0.extras != nil }
    }

    // MARK: Internal Instance Methods

    internal func indexForInserting(time: TimeType) -> Int {
        entries.firstIndex { time < $0.time } ?? entries.endIndex
    }

    internal func indexMatching(time: TimeType,
                                loudness: Loudness,
                                extras: Extras?) -> Int? {
        entries.firstIndex {
            (time, loudness, extras) == ($0.time, $0.loudness, $0.extras)
        }
    }
}
