// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

extension DynamicMap {

    // MARK: Internal Type Methods

    internal static func hasExtras(in entries: [Entry]) -> Bool {
        entries.contains { $0.extras != nil }
    }

    // MARK: Internal Instance Methods

    internal func firstIndex(time: TimeType,
                             dynamic: Dynamic,
                             extras: Extras?) -> Int? {
        entries.firstIndex {
            (time, dynamic, extras) == ($0.time, $0.dynamic, $0.extras)
        }
    }

    internal func insertionIndex(for time: TimeType) -> Int {
        entries.firstIndex { time < $0.time } ?? entries.endIndex
    }
}
