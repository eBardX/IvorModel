// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

extension InstrumentMap {

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
    /// - Throws:   ``InstrumentMap/Error/invalidAugmentationFactor(_:)`` if `factor` is not a
    ///             rational number ≥ 1; ``InstrumentMap/Error/invalidAnchor`` if `anchor` is later
    ///             than the low bound of the entries being augmented; otherwise,
    ///             ``InstrumentMap/Error/augmentFailure(_:)`` if an entry cannot be augmented.
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

            entries[idx] = StoredEntry(entryID: entry.entryID,
                                       time: newTime,
                                       instrument: entry.instrument,
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
    /// - Throws:   ``InstrumentMap/Error/invalidDiminutionFactor(_:)`` if `factor` is not a
    ///             rational number ≥ 1; ``InstrumentMap/Error/invalidAnchor`` if `anchor` is later
    ///             than the low bound of the entries being diminished; otherwise,
    ///             ``InstrumentMap/Error/diminishFailure(_:)`` if an entry cannot be diminished.
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

            entries[idx] = StoredEntry(entryID: entry.entryID,
                                       time: newTime,
                                       instrument: entry.instrument,
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
    /// - Throws:   ``InstrumentMap/Error/moveFailure(_:)`` if an entry cannot be moved.
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

            entries[idx] = StoredEntry(entryID: entry.entryID,
                                       time: newTime,
                                       instrument: entry.instrument,
                                       extras: entry.extras)
        }

        entries.sort()
    }

    /// Reverses the order of entries within a time range.
    ///
    /// Each entry is a step: its instrument holds until the next entry. So reversing mirrors the
    /// stretch each selected entry governs — up to the next selected entry, or to the range’s
    /// upper bound — and moves the entry to that stretch’s new start. Flute at 0 and piccolo at
    /// 4, reversed within 0…8, gives piccolo at 0 and flute at 4. The stretch before the first
    /// selected entry, which holds the instrument in effect before it (``defaultInstrument``
    /// unless an unselected entry precedes it), moves to the end of the range, and a new entry
    /// begins it there. Entries that share a time swap order, so a step keeps its order. The
    /// instrument after the range isn’t restored, just as the interpolating maps don’t restore
    /// their values after it.
    ///
    /// - Parameter timeRange:   The time range to mirror entry times around. `nil` resolves to the
    ///                          map’s own time range, or — when `entryIDs` is non-`nil` — the
    ///                          selected entries’ own time range.
    /// - Parameter entryIDs:    The identities of the entries to reverse, or `nil` to reverse every
    ///                          entry in the map.
    ///
    /// - Throws:   ``InstrumentMap/Error/invalidAnchor`` if `timeRange` does not contain the time
    ///             range of the entries being reversed; otherwise,
    ///             ``InstrumentMap/Error/reverseFailure(_:)`` if an entry cannot be reversed.
    public mutating func reverse(within timeRange: ClosedRange<TimeType>? = nil,
                                 entryIDs: Set<EntryID>? = nil) throws(Error) {
        guard !entries.isEmpty
        else { return }

        guard let selectedRange = _selectedTimeRange(entryIDs: entryIDs)
        else { return }

        let anchorRange = try _resolvedRange(timeRange, containing: selectedRange)
        let selectedIndices = entries.indices.filter { entryIDs?.contains(entries[$0].entryID) ?? true }

        guard let firstIndex = selectedIndices.first
        else { return }

        var newEntries = entries

        for (pos, idx) in selectedIndices.enumerated() {
            let entry = entries[idx]
            let stretchEnd = pos + 1 < selectedIndices.count ? entries[selectedIndices[pos + 1]].time : anchorRange.upperBound

            guard let newTime = Self._mirrored(stretchEnd, within: anchorRange)
            else { throw Error.reverseFailure(entry.time) }

            newEntries[idx] = StoredEntry(entryID: entry.entryID,
                                          time: newTime,
                                          instrument: entry.instrument,
                                          extras: entry.extras)
        }

        //
        // Mirroring reverses the selected entries' order in time, so reverse their order in the
        // array too, so that entries sharing a time swap as well. The stable sort then merges
        // them back in among any unselected entries.
        //
        let reversedEntries = selectedIndices.reversed().map { newEntries[$0] }

        for (idx, entry) in zip(selectedIndices, reversedEntries) {
            newEntries[idx] = entry
        }

        //
        // The stretch before the first selected entry ends up last in the range. Appended before
        // the stable sort, its new entry follows any others at its time, so it takes effect.
        //
        let firstTime = entries[firstIndex].time

        if firstTime > anchorRange.lowerBound {
            let leading = entries[..<firstIndex].last?.instrument ?? defaultInstrument

            guard let newTime = Self._mirrored(firstTime, within: anchorRange)
            else { throw Error.reverseFailure(firstTime) }

            if !newEntries.contains(where: { $0.time == newTime && $0.instrument == leading && $0.extras == nil }) {
                newEntries.append(StoredEntry(time: newTime,
                                              instrument: leading,
                                              extras: nil))
            }
        }

        newEntries.sort()

        entries = newEntries
    }

    // MARK: Private Type Methods

    //
    // `time` mirrored within `range`: as far after its lower bound as `time` is before its
    // upper bound.
    //
    private static func _mirrored(_ time: TimeType,
                                  within range: ClosedRange<TimeType>) -> TimeType? {
        guard let dirDur = time.duration(to: range.upperBound)
        else { return nil }

        return range.lowerBound.moved(by: dirDur)
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

// MARK: -

extension InstrumentMap where TimeType == BeatTime {

    // MARK: Public Instance Methods

    /// Quantizes entry times to the nearest grid point defined by `quantizer`.
    ///
    /// Unlike `augment`/`diminish`/`move`/`reverse`, this never throws — an already-built
    /// ``BeatQuantizer`` has already had its factors validated, so there is nothing left for
    /// this call to fail on, and snapping an entry to a grid point can never overflow the way a
    /// relative move can.
    ///
    /// - Parameter quantizer:   The quantizer whose grid to snap entry times to.
    /// - Parameter entryIDs:    The identities of the entries to quantize, or `nil` to quantize
    ///                          every entry in the map.
    public mutating func quantize(using quantizer: BeatQuantizer,
                                  entryIDs: Set<EntryID>? = nil) {
        guard !entries.isEmpty
        else { return }

        for (idx, entry) in entries.enumerated() {
            guard entryIDs?.contains(entry.entryID) ?? true
            else { continue }

            entries[idx] = StoredEntry(entryID: entry.entryID,
                                       time: quantizer.quantize(entry.time),
                                       instrument: entry.instrument,
                                       extras: entry.extras)
        }

        entries.sort()
    }
}
