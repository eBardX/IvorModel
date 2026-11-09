// © 2026 John Gary Pusey (see LICENSE.md)

private import XestiNumbers

extension PedalTable {

    // MARK: Public Instance Methods

    /// Reduces the entries of this pedal table, as `mode` describes, without changing when the
    /// pedal goes down or comes up.
    ///
    /// Entries are considered one time at a time, against the level in effect before that time.
    /// Of several entries at one time, only the last sets the level, so the others are removed —
    /// except that a re-pedal (the pedal down before and after, and let up in between) keeps one
    /// up entry and the last entry. An entry whose level, after `mode` is applied, repeats the
    /// level already in effect is removed too.
    ///
    /// An entry that carries extras is never removed, though ``ThinMode/snap`` still snaps its
    /// level. When one is kept ahead of other entries at its time, the last entry at that time is
    /// kept as well, so the level from then on doesn’t change.
    ///
    /// - Parameter mode:   How to reduce the entries.
    ///
    /// - Returns:  The identities of the removed entries, in table order.
    @discardableResult
    public mutating func thin(_ mode: ThinMode) -> [EntryID] {
        var kept: [StoredEntry] = []
        var removedEntryIDs: [EntryID] = []
        var current: Pedal.Level = .off
        var position = entries.startIndex

        while position < entries.endIndex {
            let time = entries[position].time
            var end = position

            while end < entries.endIndex, entries[end].time == time {
                end += 1
            }

            let group = entries[position..<end].map { Self._applying(mode, to: $0) }
            let keeps = Self._keeps(group,
                                    after: current,
                                    mode: mode)

            for (entry, isKept) in zip(group, keeps) {
                if isKept {
                    if let last = kept.last, last == entry {
                        removedEntryIDs.append(entry.entryID)
                    } else {
                        kept.append(entry)
                    }
                } else {
                    removedEntryIDs.append(entry.entryID)
                }
            }

            if let final = group.last, keeps.last == true {
                current = final.level
            }

            position = end
        }

        self = Self(entries: kept)

        return removedEntryIDs
    }

    // MARK: Private Type Methods

    private static func _applying(_ mode: ThinMode,
                                  to entry: StoredEntry) -> StoredEntry {
        guard mode == .snap
        else { return entry }

        return StoredEntry(entryID: entry.entryID,
                           time: entry.time,
                           level: entry.level.isDown ? .on : .off,
                           extras: entry.extras)
    }

    // Whether the last entry at a time, at `level`, changes the level in effect, `current`,
    // enough to keep.
    private static func _isSignificant(_ level: Pedal.Level,
                                       after current: Pedal.Level,
                                       mode: ThinMode) -> Bool {
        guard level != current
        else { return false }

        switch mode {
        case let .merge(tolerance):
            return level == .off
                || level == .on
                || level.isDown != current.isDown
                || (level.numberValue - current.numberValue).magnitude >= tolerance.numberValue

        case .snap:
            return true
        }
    }

    // Which of one time's entries (`group`, with `mode` already applied) to keep, given the
    // level in effect before them.
    private static func _keeps(_ group: [StoredEntry],
                               after current: Pedal.Level,
                               mode: ThinMode) -> [Bool] {
        guard let final = group.last
        else { return [] }

        var keeps = group.map { $0.extras != nil }

        let lastIndex = group.count - 1
        let isRepedal = current.isDown
            && final.level.isDown
            && group.dropLast().contains { !$0.level.isDown }

        if isRepedal,
           let upIndex = group.indices.dropLast().last(where: { !group[$0].level.isDown }) {
            keeps[upIndex] = true
            keeps[lastIndex] = true
        } else if _isSignificant(final.level,
                                 after: current,
                                 mode: mode) {
            keeps[lastIndex] = true
        }

        if keeps.dropLast().contains(true) {
            keeps[lastIndex] = true
        }

        return keeps
    }
}
