// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

extension PartMarkTable {

    // MARK: Public Instance Properties

    /// The closed range of times the marks cover — from the earliest mark’s time to the latest
    /// mark’s time or fermata’s end — or `nil` if the table is empty.
    public var timeRange: ClosedRange<TimeType>? {
        Self._timeRange(of: entries)
    }

    // MARK: Public Instance Methods

    /// Augments entry times, and fermata spans and other written lengths, by a rational factor.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch the selected entries.
    /// - Parameter anchor:     The low time bound to stretch times relative to. `nil` resolves to
    ///                         the selected entries’ own range.
    /// - Parameter entryIDs:   The identities of the entries to augment, or `nil` to augment every
    ///                         entry in the table.
    ///
    /// - Throws:   ``PartMarkTable/Error/invalidAugmentationFactor(_:)`` if `factor` is not a
    ///             rational number ≥ 1; ``PartMarkTable/Error/invalidAnchor`` if `anchor` is later
    ///             than the low bound of the entries being augmented; otherwise,
    ///             ``PartMarkTable/Error/augmentFailure(_:)`` if an entry cannot be augmented.
    public mutating func augment(by factor: Number,
                                 anchor: TimeType? = nil,
                                 entryIDs: Set<EntryID>? = nil) throws(Error) {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidAugmentationFactor(factor) }

        guard factor > 1
        else { return }

        try _scale(by: factor,
                   anchor: anchor,
                   entryIDs: entryIDs,
                   failure: Error.augmentFailure)
    }

    /// Diminishes entry times, and fermata spans and other written lengths, by a rational factor.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to compress the selected entries.
    /// - Parameter anchor:     The low time bound to compress times relative to. `nil` resolves to
    ///                         the selected entries’ own range.
    /// - Parameter entryIDs:   The identities of the entries to diminish, or `nil` to diminish
    ///                         every entry in the table.
    ///
    /// - Throws:   ``PartMarkTable/Error/invalidDiminutionFactor(_:)`` if `factor` is not a
    ///             rational number ≥ 1; ``PartMarkTable/Error/invalidAnchor`` if `anchor` is later
    ///             than the low bound of the entries being diminished; otherwise,
    ///             ``PartMarkTable/Error/diminishFailure(_:)`` if an entry cannot be diminished.
    public mutating func diminish(by factor: Number,
                                  anchor: TimeType? = nil,
                                  entryIDs: Set<EntryID>? = nil) throws(Error) {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidDiminutionFactor(factor) }

        guard factor > 1
        else { return }

        try _scale(by: 1 / factor,
                   anchor: anchor,
                   entryIDs: entryIDs,
                   failure: Error.diminishFailure)
    }

    /// Moves entry times by a directed duration. Fermata spans are unchanged.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move the selected entry
    ///                                 times.
    /// - Parameter entryIDs:           The identities of the entries to move, or `nil` to move
    ///                                 every entry in the table.
    ///
    /// - Throws:   ``PartMarkTable/Error/moveFailure(_:)`` if an entry cannot be moved.
    public mutating func move(by directedDuration: DirectedDuration<TimeType.DurationType>,
                              entryIDs: Set<EntryID>? = nil) throws(Error) {
        guard !entries.isEmpty,
              !directedDuration.duration.isZero
        else { return }

        var newEntries = entries

        for (idx, entry) in entries.enumerated() {
            guard entryIDs?.contains(entry.entryID) ?? true
            else { continue }

            guard let newTime = entry.time.moved(by: directedDuration)
            else { throw Error.moveFailure(entry.time) }

            newEntries[idx] = StoredEntry(entryID: entry.entryID,
                                          time: newTime,
                                          mark: entry.mark)
        }

        entries = Self._sorted(newEntries)
    }

    /// Reverses the order of entries within a time range.
    ///
    /// The reversed passage is a mirror image: a caesura moves to its mirrored moment, and a
    /// fermata’s span is mirrored, so it starts where its old end is mirrored to and keeps its
    /// length. Entries that share a time swap order.
    ///
    /// - Parameter timeRange:  The time range to mirror entries around. `nil` resolves to the
    ///                         selected entries’ own time range, fermata spans included.
    /// - Parameter entryIDs:   The identities of the entries to reverse, or `nil` to reverse every
    ///                         entry in the table.
    ///
    /// - Throws:   ``PartMarkTable/Error/invalidAnchor`` if `timeRange` does not contain the time
    ///             range of the entries being reversed; otherwise,
    ///             ``PartMarkTable/Error/reverseFailure(_:)`` if an entry cannot be reversed.
    public mutating func reverse(within timeRange: ClosedRange<TimeType>? = nil,
                                 entryIDs: Set<EntryID>? = nil) throws(Error) {
        guard let selectedRange = _selectedTimeRange(entryIDs: entryIDs)
        else { return }

        let anchorRange = try _resolvedRange(timeRange, containing: selectedRange)
        let selectedIndices = entries.indices.filter { entryIDs?.contains(entries[$0].entryID) ?? true }
        var newEntries = entries

        for idx in selectedIndices {
            let entry = entries[idx]

            guard let end = Self._end(of: entry),
                  let dirDur = end.duration(to: anchorRange.upperBound),
                  let newTime = anchorRange.lowerBound.moved(by: dirDur)
            else { throw Error.reverseFailure(entry.time) }

            newEntries[idx] = StoredEntry(entryID: entry.entryID,
                                          time: newTime,
                                          mark: entry.mark)
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

        entries = Self._sorted(newEntries)
    }

    // MARK: Private Type Methods

    //
    // Where an entry ends: a fermata's span end, or a caesura's own moment.
    //
    private static func _end(of entry: StoredEntry) -> TimeType? {
        guard let span = entry.mark.span
        else { return entry.time }

        return entry.time.moved(by: DirectedDuration(duration: span,
                                                     direction: .forward))
    }

    //
    // A stable sort by time, then the identical-neighbor fold `insert(time:mark:)` applies.
    //
    private static func _sorted(_ entries: [StoredEntry]) -> [StoredEntry] {
        deduplicated(entries.enumerated()
            .sorted { ($0.element.time, $0.offset) < ($1.element.time, $1.offset) }
            .map(\.element))
    }

    private static func _timeRange(of entries: [StoredEntry]) -> ClosedRange<TimeType>? {
        guard let lowerBound = entries.map(\.time).min(),
              let upperBound = entries.compactMap(_end).max()
        else { return nil }

        return lowerBound...upperBound
    }

    // MARK: Private Instance Methods

    //
    // `nil` resolves to `selectedRange` — safe by construction, since it's derived from the very
    // entries being operated on. A caller-supplied anchor must be no later than that range's low
    // bound.
    //
    private func _resolvedLowerBound(_ anchor: TimeType?,
                                     containing selectedRange: ClosedRange<TimeType>) throws(Error) -> TimeType {
        guard let anchor
        else { return selectedRange.lowerBound }

        guard anchor <= selectedRange.lowerBound
        else { throw Error.invalidAnchor }

        return anchor
    }

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
    // Scales each selected entry's distance from the anchor, and its mark's written lengths, by
    // `factor` (> 1 to augment, < 1 to diminish).
    //
    private mutating func _scale(by factor: Number,
                                 anchor: TimeType?,
                                 entryIDs: Set<EntryID>?,
                                 failure: (TimeType) -> Error) throws(Error) {
        guard let selectedRange = _selectedTimeRange(entryIDs: entryIDs)
        else { return }

        let loTime = try _resolvedLowerBound(anchor, containing: selectedRange)
        var newEntries = entries

        for (idx, entry) in entries.enumerated() {
            guard entryIDs?.contains(entry.entryID) ?? true
            else { continue }

            guard let result = loTime.duration(to: entry.time),
                  let duration = result.duration.multiplied(by: factor),
                  let newTime = loTime.moved(by: DirectedDuration(duration: duration,
                                                                  direction: result.direction)),
                  let newMark = entry.mark.scaled(by: factor)
            else { throw failure(entry.time) }

            newEntries[idx] = StoredEntry(entryID: entry.entryID,
                                          time: newTime,
                                          mark: newMark)
        }

        entries = Self._sorted(newEntries)
    }

    private func _selectedTimeRange(entryIDs: Set<EntryID>?) -> ClosedRange<TimeType>? {
        Self._timeRange(of: entryIDs.map { ids in entries.filter { ids.contains($0.entryID) } } ?? entries)
    }
}

// MARK: -

extension PartMarkTable where TimeType == BeatTime {

    // MARK: Public Instance Methods

    /// Quantizes entry times, and the ends of fermata spans, to the nearest grid point defined by
    /// `quantizer`. A span that would shrink to nothing keeps one grid unit.
    ///
    /// - Parameter quantizer:  The quantizer whose grid to snap times to.
    /// - Parameter entryIDs:   The identities of the entries to quantize, or `nil` to quantize
    ///                         every entry in the table.
    public mutating func quantize(using quantizer: BeatQuantizer,
                                  entryIDs: Set<EntryID>? = nil) {
        var newEntries = entries

        for (idx, entry) in entries.enumerated() {
            guard entryIDs?.contains(entry.entryID) ?? true
            else { continue }

            let newTime = quantizer.quantize(entry.time)
            var newMark = entry.mark

            if let span = entry.mark.span,
               let end = entry.time.moved(by: DirectedDuration(duration: span,
                                                               direction: .forward)) {
                let rawSpan = quantizer.quantize(end) - newTime

                if let newSpan = PositiveDuration(rawSpan.isZero ? quantizer.gridUnit : rawSpan) {
                    newMark = entry.mark.withSpan(newSpan)
                }
            }

            newEntries[idx] = StoredEntry(entryID: entry.entryID,
                                          time: newTime,
                                          mark: newMark)
        }

        entries = Self._sorted(newEntries)
    }
}
