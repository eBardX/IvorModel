// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

extension PanMap {

    // MARK: Public Instance Methods

    /// Augments entry times by a rational factor.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch the selected entry times.
    /// - Parameter anchor:     The low time bound to stretch times relative to. `nil` resolves to
    ///                         the map’s own range, or — when `entryIDs` is non-`nil` — the
    ///                         selected entries’ own range.
    /// - Parameter entryIDs:   The identities of the entries to augment, or `nil` to augment every
    ///                         entry in the map.
    ///
    /// - Throws:   ``PanMap/Error/invalidAugmentationFactor(_:)`` if `factor` is not a rational
    ///             number ≥ 1; ``PanMap/Error/invalidAnchor`` if `anchor` is later than the low
    ///             bound of the entries being augmented; otherwise,
    ///             ``PanMap/Error/augmentFailure(_:)`` if an entry cannot be augmented.
    public mutating func augment(by factor: Number,
                                 anchor: TimeType? = nil,
                                 entryIDs: Set<EntryID>? = nil) throws(Error) {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidAugmentationFactor(factor) }

        guard !entries.isEmpty,
              factor > 1
        else { return }

        guard let selectedRange = _selectedTimeRange(entryIDs: entryIDs)
        else { return }

        let loTime = try _resolvedLowerBound(anchor, containing: selectedRange)

        for (idx, entry) in entries.enumerated() {
            guard entryIDs?.contains(entry.entryID) ?? true
            else { continue }

            guard let result = loTime.duration(to: entry.time),
                  let duration = result.duration.multiplied(by: factor),
                  let newTime = loTime.moved(by: DirectedDuration(duration: duration,
                                                                  direction: result.direction))
            else { throw Error.augmentFailure(entry.time) }

            entries[idx] = Entry(entryID: entry.entryID,
                                 time: newTime,
                                 pan: entry.pan,
                                 extras: entry.extras)
        }

        entries.sort()
    }

    /// Diminishes entry times by a rational factor.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to compress the selected entry
    ///                         times.
    /// - Parameter anchor:     The low time bound to compress times relative to. `nil` resolves to
    ///                         the map’s own range, or — when `entryIDs` is non-`nil` — the
    ///                         selected entries’ own range.
    /// - Parameter entryIDs:   The identities of the entries to diminish, or `nil` to diminish
    ///                         every entry in the map.
    ///
    /// - Throws:   ``PanMap/Error/invalidDiminutionFactor(_:)`` if `factor` is not a rational
    ///             number ≥ 1; ``PanMap/Error/invalidAnchor`` if `anchor` is later than the low
    ///             bound of the entries being diminished; otherwise,
    ///             ``PanMap/Error/diminishFailure(_:)`` if an entry cannot be diminished.
    public mutating func diminish(by factor: Number,
                                  anchor: TimeType? = nil,
                                  entryIDs: Set<EntryID>? = nil) throws(Error) {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidDiminutionFactor(factor) }

        guard !entries.isEmpty,
              factor > 1
        else { return }

        guard let selectedRange = _selectedTimeRange(entryIDs: entryIDs)
        else { return }

        let loTime = try _resolvedLowerBound(anchor, containing: selectedRange)

        for (idx, entry) in entries.enumerated() {
            guard entryIDs?.contains(entry.entryID) ?? true
            else { continue }

            guard let result = loTime.duration(to: entry.time),
                  let duration = result.duration.divided(by: factor),
                  let newTime = loTime.moved(by: DirectedDuration(duration: duration,
                                                                  direction: result.direction))
            else { throw Error.diminishFailure(entry.time) }

            entries[idx] = Entry(entryID: entry.entryID,
                                 time: newTime,
                                 pan: entry.pan,
                                 extras: entry.extras)
        }

        entries.sort()
    }

    /// Moves entry times by a directed duration.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move the selected entry
    ///                                 times.
    /// - Parameter entryIDs:           The identities of the entries to move, or `nil` to move
    ///                                 every entry in the map.
    ///
    /// - Throws:   ``PanMap/Error/moveFailure(_:)`` if an entry cannot be moved.
    public mutating func move(by directedDuration: DirectedDuration<TimeType.DurationType>,
                              entryIDs: Set<EntryID>? = nil) throws(Error) {
        guard !entries.isEmpty,
              !directedDuration.duration.isZero
        else { return }

        for (idx, entry) in entries.enumerated() {
            guard entryIDs?.contains(entry.entryID) ?? true
            else { continue }

            guard let newTime = entry.time.moved(by: directedDuration)
            else { throw Error.moveFailure(entry.time) }

            entries[idx] = Entry(entryID: entry.entryID,
                                 time: newTime,
                                 pan: entry.pan,
                                 extras: entry.extras)
        }

        entries.sort()
    }

    /// Reverses the order of entries within a time range.
    ///
    /// - Parameter timeRange:   The time range to mirror entry times around. `nil` resolves to the
    ///                          map’s own time range, or — when `entryIDs` is non-`nil` — the
    ///                          selected entries’ own time range.
    /// - Parameter entryIDs:    The identities of the entries to reverse, or `nil` to reverse every
    ///                          entry in the map.
    ///
    /// - Throws:   ``PanMap/Error/invalidAnchor`` if `timeRange` does not contain the time range of
    ///             the entries being reversed; otherwise, ``PanMap/Error/reverseFailure(_:)`` if an
    ///             entry cannot be reversed.
    public mutating func reverse(within timeRange: ClosedRange<TimeType>? = nil,
                                 entryIDs: Set<EntryID>? = nil) throws(Error) {
        guard !entries.isEmpty
        else { return }

        guard let selectedRange = _selectedTimeRange(entryIDs: entryIDs)
        else { return }

        let anchorRange = try _resolvedRange(timeRange, containing: selectedRange)
        let hiTime = anchorRange.upperBound
        let loTime = anchorRange.lowerBound

        for (idx, entry) in entries.enumerated() {
            guard entryIDs?.contains(entry.entryID) ?? true
            else { continue }

            guard let dirDur = entry.time.duration(to: hiTime),
                  let newTime = loTime.moved(by: dirDur)
            else { throw Error.reverseFailure(entry.time) }

            entries[idx] = Entry(entryID: entry.entryID,
                                 time: newTime,
                                 pan: entry.pan,
                                 extras: entry.extras)
        }

        entries.sort()
    }

    // MARK: Private Instance Methods

    //
    // `nil` resolves to `containing` (the selected entries' own range) — safe by construction,
    // since it's derived from the very entries being operated on. A caller-supplied anchor must be
    // no later than that range's low bound, or the stretch it pivots would be applied against
    // entries it doesn't actually bound.
    //
    private func _resolvedLowerBound(_ anchor: TimeType?,
                                     containing selectedRange: ClosedRange<TimeType>) throws(Error) -> TimeType {
        guard let anchor
        else { return selectedRange.lowerBound }

        guard anchor <= selectedRange.lowerBound
        else { throw Error.invalidAnchor }

        return anchor
    }

    //
    // `nil` resolves to `selectedRange` — safe by construction, since it's derived from the very
    // entries being operated on. A caller-supplied range must fully contain `selectedRange`, or
    // the mirror it pivots around would reflect entries it doesn't actually bound.
    //
    private func _resolvedRange(_ anchorRange: ClosedRange<TimeType>?,
                                containing selectedRange: ClosedRange<TimeType>) throws(Error) -> ClosedRange<TimeType> {
        guard let anchorRange
        else { return selectedRange }

        guard anchorRange.lowerBound <= selectedRange.lowerBound,
              anchorRange.upperBound >= selectedRange.upperBound
        else { throw Error.invalidAnchor }

        return anchorRange
    }

    //
    // `entries` is always kept sorted by time, so the first and last elements of any
    // (order-preserving) subsequence of it bound that subsequence's time range.
    //
    private func _selectedTimeRange(entryIDs: Set<EntryID>?) -> ClosedRange<TimeType>? {
        let selected = entryIDs.map { ids in entries.filter { ids.contains($0.entryID) } } ?? entries

        guard let first = selected.first,
              let last = selected.last
        else { return nil }

        return first.time...last.time
    }
}
