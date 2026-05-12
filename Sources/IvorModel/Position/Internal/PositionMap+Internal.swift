internal import XestiTools

extension PositionMap {

    // MARK: Internal Type Methods

    internal static func determineHasExtras(_ entries: [Entry]) -> Bool {
        entries.contains { $0.extras != nil }
    }

    // MARK: Internal Instance Methods

    internal func indexForInserting(time: TimeType) -> Int {
        entries.firstIndex { time < $0.time } ?? entries.endIndex
    }

    internal func indexMatching(time: TimeType,
                                position: Position,
                                extras: Extras?) -> Int? {
        entries.firstIndex {
            (time, position, extras) == ($0.time, $0.position, $0.extras)
        }
    }
}
