// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiNumbers

extension Part {

    // MARK: Public Instance Methods

    /// Augments note attack times and durations by a rational factor, along with any parameter
    /// maps selected by `applyTo`.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch the selected note
    ///                         timings.
    /// - Parameter anchor:     The low time bound to stretch attack times relative to. `nil`
    ///                         resolves to the start of everything being augmented: the notes
    ///                         and the entries of every map `applyTo` selects, or — when
    ///                         `noteIDs` is non-`nil` — the selected notes’ own range.
    /// - Parameter noteIDs:    The identities of the notes to augment, or `nil` to augment every
    ///                         note in the note table. Also narrows which entries of any map
    ///                         selected by `applyTo` are carried along, to those falling within
    ///                         the selected notes’ own time range.
    /// - Parameter applyTo:    The parameter maps to augment along with the note table.
    ///                         Defaults to every map.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` if the note table cannot be augmented, or
    ///             the corresponding map-failure case if a selected map cannot be augmented.
    public mutating func augment(by factor: Number,
                                 anchor: TimeType? = nil,
                                 noteIDs: Set<NoteID>? = nil,
                                 applyTo: TransformTargets = .all) throws(Error) {
        //
        // Resolve the default once, so the note table and every map scale about the same anchor.
        //
        let resolvedAnchor = anchor ?? transformTimeRange(noteIDs: noteIDs,
                                                          applyTo: applyTo)?.lowerBound

        var newNoteTable = noteTable

        do {
            try newNoteTable.augment(by: factor,
                                     anchor: resolvedAnchor,
                                     noteIDs: noteIDs)
        } catch {
            throw Error.noteTableFailure(error)
        }

        var newDynamicMap = dynamicMap
        var newInstrumentTable = instrumentTable
        var newPanMap = panMap

        if applyTo.contains(.dynamic) {
            do {
                try newDynamicMap.augment(by: factor,
                                          anchor: resolvedAnchor,
                                          entryIDs: _dynamicEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.dynamicMapFailure(error)
            }
        }

        if applyTo.contains(.instrument) {
            do {
                try newInstrumentTable.augment(by: factor,
                                               anchor: resolvedAnchor,
                                               entryIDs: _instrumentEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.instrumentTableFailure(error)
            }
        }

        if applyTo.contains(.pan) {
            do {
                try newPanMap.augment(by: factor,
                                      anchor: resolvedAnchor,
                                      entryIDs: _panEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.panMapFailure(error)
            }
        }

        noteTable = newNoteTable
        dynamicMap = newDynamicMap
        instrumentTable = newInstrumentTable
        panMap = newPanMap
    }

    /// Diminishes note attack times and durations by a rational factor, along with any
    /// parameter maps selected by `applyTo`.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to compress the selected note
    ///                         timings.
    /// - Parameter anchor:     The low time bound to compress attack times relative to. `nil`
    ///                         resolves to the start of everything being diminished: the notes
    ///                         and the entries of every map `applyTo` selects, or — when
    ///                         `noteIDs` is non-`nil` — the selected notes’ own range.
    /// - Parameter noteIDs:    The identities of the notes to diminish, or `nil` to diminish
    ///                         every note in the note table. Also narrows which entries of any
    ///                         map selected by `applyTo` are carried along, to those falling
    ///                         within the selected notes’ own time range.
    /// - Parameter applyTo:    The parameter maps to diminish along with the note table.
    ///                         Defaults to every map.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` if the note table cannot be diminished, or
    ///             the corresponding map-failure case if a selected map cannot be diminished.
    public mutating func diminish(by factor: Number,
                                  anchor: TimeType? = nil,
                                  noteIDs: Set<NoteID>? = nil,
                                  applyTo: TransformTargets = .all) throws(Error) {
        //
        // Resolve the default once, so the note table and every map scale about the same anchor.
        //
        let resolvedAnchor = anchor ?? transformTimeRange(noteIDs: noteIDs,
                                                          applyTo: applyTo)?.lowerBound

        var newNoteTable = noteTable

        do {
            try newNoteTable.diminish(by: factor,
                                      anchor: resolvedAnchor,
                                      noteIDs: noteIDs)
        } catch {
            throw Error.noteTableFailure(error)
        }

        var newDynamicMap = dynamicMap
        var newInstrumentTable = instrumentTable
        var newPanMap = panMap

        if applyTo.contains(.dynamic) {
            do {
                try newDynamicMap.diminish(by: factor,
                                           anchor: resolvedAnchor,
                                           entryIDs: _dynamicEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.dynamicMapFailure(error)
            }
        }

        if applyTo.contains(.instrument) {
            do {
                try newInstrumentTable.diminish(by: factor,
                                                anchor: resolvedAnchor,
                                                entryIDs: _instrumentEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.instrumentTableFailure(error)
            }
        }

        if applyTo.contains(.pan) {
            do {
                try newPanMap.diminish(by: factor,
                                       anchor: resolvedAnchor,
                                       entryIDs: _panEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.panMapFailure(error)
            }
        }

        noteTable = newNoteTable
        dynamicMap = newDynamicMap
        instrumentTable = newInstrumentTable
        panMap = newPanMap
    }

    /// Inverts note pitches around a pitch range.
    ///
    /// - Parameter pitchRange: The pitch range to invert pitches around. `nil` resolves to the
    ///                         note table’s own pitch range, or — when `noteIDs` is non-`nil` —
    ///                         the selected notes’ own pitch range.
    /// - Parameter noteIDs:    The identities of the notes to invert, or `nil` to invert every
    ///                         note in the note table.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` if the note table cannot be inverted.
    ///
    /// - Note: No parameter map has a pitch axis, so — unlike the other five transforms — this
    ///         one never carries any map along.
    public mutating func invert(around pitchRange: ClosedRange<PitchType>? = nil,
                                noteIDs: Set<NoteID>? = nil) throws(Error) {
        var newNoteTable = noteTable

        do {
            try newNoteTable.invert(around: pitchRange,
                                    noteIDs: noteIDs)
        } catch {
            throw Error.noteTableFailure(error)
        }

        noteTable = newNoteTable
    }

    /// Moves note attack times by a directed duration, along with any parameter maps selected
    /// by `applyTo`.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move the selected note
    ///                                 attack times.
    /// - Parameter noteIDs:            The identities of the notes to move, or `nil` to move
    ///                                 every note in the note table. Also narrows which entries
    ///                                 of any map selected by `applyTo` are carried along, to
    ///                                 those falling within the selected notes’ own time range.
    /// - Parameter applyTo:            The parameter maps to move along with the note table.
    ///                                 Defaults to every map.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` if the note table cannot be moved, or the
    ///             corresponding map-failure case if a selected map cannot be moved.
    public mutating func move(by directedDuration: DirectedDuration<DurationType>,
                              noteIDs: Set<NoteID>? = nil,
                              applyTo: TransformTargets = .all) throws(Error) {
        var newNoteTable = noteTable

        do {
            try newNoteTable.move(by: directedDuration,
                                  noteIDs: noteIDs)
        } catch {
            throw Error.noteTableFailure(error)
        }

        var newDynamicMap = dynamicMap
        var newInstrumentTable = instrumentTable
        var newPanMap = panMap

        if applyTo.contains(.dynamic) {
            do {
                try newDynamicMap.move(by: directedDuration,
                                       entryIDs: _dynamicEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.dynamicMapFailure(error)
            }
        }

        if applyTo.contains(.instrument) {
            do {
                try newInstrumentTable.move(by: directedDuration,
                                            entryIDs: _instrumentEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.instrumentTableFailure(error)
            }
        }

        if applyTo.contains(.pan) {
            do {
                try newPanMap.move(by: directedDuration,
                                   entryIDs: _panEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.panMapFailure(error)
            }
        }

        noteTable = newNoteTable
        dynamicMap = newDynamicMap
        instrumentTable = newInstrumentTable
        panMap = newPanMap
    }

    /// Reverses the order of notes within a time range, along with any parameter maps selected
    /// by `applyTo`.
    ///
    /// - Parameter timeRange:  The time range to mirror attack times around. `nil` resolves to
    ///                         the span of everything being reversed: the notes and the entries
    ///                         of every map `applyTo` selects, or — when `noteIDs` is non-`nil`
    ///                         — the selected notes’ own time range.
    /// - Parameter noteIDs:    The identities of the notes to reverse, or `nil` to reverse every
    ///                         note in the note table. Also narrows which entries of any map
    ///                         selected by `applyTo` are carried along, to those falling within
    ///                         the selected notes’ own time range.
    /// - Parameter applyTo:    The parameter maps to reverse along with the note table.
    ///                         Defaults to every map.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` if the note table cannot be reversed, or
    ///             the corresponding map-failure case if a selected map cannot be reversed.
    public mutating func reverse(within timeRange: ClosedRange<TimeType>? = nil,
                                 noteIDs: Set<NoteID>? = nil,
                                 applyTo: TransformTargets = .all) throws(Error) {
        //
        // Resolve the default once, so the note table and every map mirror about the same axis.
        //
        let resolvedRange = timeRange ?? transformTimeRange(noteIDs: noteIDs,
                                                            applyTo: applyTo)

        var newNoteTable = noteTable

        do {
            try newNoteTable.reverse(within: resolvedRange,
                                     noteIDs: noteIDs)
        } catch {
            throw Error.noteTableFailure(error)
        }

        var newDynamicMap = dynamicMap
        var newInstrumentTable = instrumentTable
        var newPanMap = panMap

        if applyTo.contains(.dynamic) {
            do {
                try newDynamicMap.reverse(within: resolvedRange,
                                          entryIDs: _dynamicEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.dynamicMapFailure(error)
            }
        }

        if applyTo.contains(.instrument) {
            do {
                try newInstrumentTable.reverse(within: resolvedRange,
                                               entryIDs: _instrumentEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.instrumentTableFailure(error)
            }
        }

        if applyTo.contains(.pan) {
            do {
                try newPanMap.reverse(within: resolvedRange,
                                      entryIDs: _panEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.panMapFailure(error)
            }
        }

        noteTable = newNoteTable
        dynamicMap = newDynamicMap
        instrumentTable = newInstrumentTable
        panMap = newPanMap
    }

    /// Transposes note pitches by a directed interval.
    ///
    /// - Parameter directedInterval:   The directed interval by which to transpose the selected
    ///                                 pitches.
    /// - Parameter noteIDs:            The identities of the notes to transpose, or `nil` to
    ///                                 transpose every note in the note table.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` if the note table cannot be transposed.
    ///
    /// - Note: No parameter map has a pitch axis, so — unlike the other five transforms — this
    ///         one never carries any map along.
    public mutating func transpose(by directedInterval: DirectedInterval<IntervalType>,
                                   noteIDs: Set<NoteID>? = nil) throws(Error) {
        var newNoteTable = noteTable

        do {
            try newNoteTable.transpose(by: directedInterval,
                                       noteIDs: noteIDs)
        } catch {
            throw Error.noteTableFailure(error)
        }

        noteTable = newNoteTable
    }
}

// MARK: -

extension Part where TimeType == BeatTime {

    // MARK: Public Instance Methods

    /// Quantizes note attack and release times to the nearest subdivision given by `factors`,
    /// along with any parameter maps selected by `applyTo`.
    ///
    /// - Parameter factors:    An array of positive integer subdivision factors.
    /// - Parameter noteIDs:    The identities of the notes to quantize, or `nil` to quantize
    ///                         every note in the note table. Also narrows which entries of any
    ///                         map selected by `applyTo` are carried along, to those falling
    ///                         within the selected notes’ own time range.
    /// - Parameter applyTo:    The parameter maps to quantize along with the note table.
    ///                         Defaults to ``TransformTargets/all``.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` wrapping
    ///             ``NoteTable/Error/emptyQuantizationFactors`` or
    ///             ``NoteTable/Error/invalidQuantizationFactor(_:)`` if `factors` is invalid.
    public mutating func quantize(to factors: [Int],
                                  noteIDs: Set<NoteID>? = nil,
                                  applyTo: TransformTargets = .all) throws(Error) {
        let quantizer: BeatQuantizer

        do {
            quantizer = try BeatQuantizer(factors: factors)
        } catch {
            switch error {
            case .emptyFactors:
                throw Error.noteTableFailure(.emptyQuantizationFactors)

            case let .invalidFactor(factor):
                throw Error.noteTableFailure(.invalidQuantizationFactor(factor))
            }
        }

        quantize(to: quantizer,
                 noteIDs: noteIDs,
                 applyTo: applyTo)
    }

    /// Quantizes note attack and release times to the nearest grid point defined by `quantizer`,
    /// along with any parameter maps selected by `applyTo`.
    ///
    /// Unlike ``quantize(to:noteIDs:applyTo:)-(_,_,_)``, this never throws — an already-built
    /// ``BeatQuantizer`` has already had its factors validated, so there is nothing left for this
    /// call to fail on. This is the overload ``Work``’s whole-work and targeted quantize variants
    /// (`Work+Quantize.swift`) call, so a single `BeatQuantizer` can be validated once and reused
    /// across every part without re-validating per part.
    ///
    /// - Parameter quantizer:  The quantizer whose grid to snap attack/release times to.
    /// - Parameter noteIDs:    The identities of the notes to quantize, or `nil` to quantize
    ///                         every note in the note table. Also narrows which entries of any
    ///                         map selected by `applyTo` are carried along, to those falling
    ///                         within the selected notes’ own time range.
    /// - Parameter applyTo:    The parameter maps to quantize along with the note table.
    ///                         Defaults to ``TransformTargets/all``.
    public mutating func quantize(to quantizer: BeatQuantizer,
                                  noteIDs: Set<NoteID>? = nil,
                                  applyTo: TransformTargets = .all) {
        noteTable.quantize(using: quantizer,
                           noteIDs: noteIDs)

        if applyTo.contains(.dynamic) {
            dynamicMap.quantize(using: quantizer,
                                entryIDs: _dynamicEntryIDs(forNoteIDs: noteIDs))
        }

        if applyTo.contains(.instrument) {
            instrumentTable.quantize(using: quantizer,
                                     entryIDs: _instrumentEntryIDs(forNoteIDs: noteIDs))
        }

        if applyTo.contains(.pan) {
            panMap.quantize(using: quantizer,
                            entryIDs: _panEntryIDs(forNoteIDs: noteIDs))
        }
    }
}

// MARK: -

extension Part {

    // MARK: Internal Instance Methods

    //
    // The one range a time transform's default resolves from, shared by the note table and every
    // map it carries, so they all scale or mirror about the same point. A `noteIDs` selection
    // resolves to the selected notes' own range, since the carried map entries are those inside
    // it. A whole part resolves to the span of its notes together with the entries of every map
    // `applyTo` selects: only the layers that move. Module-internal so `Work` can widen it across
    // the targeted parts and the tempo map.
    //
    internal func transformTimeRange(noteIDs: Set<NoteID>?,
                                     applyTo: TransformTargets) -> ClosedRange<TimeType>? {
        if let noteIDs {
            return noteTable.selectedTimeRange(noteIDs: noteIDs)
        }

        var bounds: [TimeType] = []

        if let noteRange = noteTable.timeRange {
            bounds += [noteRange.lowerBound, noteRange.upperBound]
        }

        if applyTo.contains(.dynamic),
           let first = dynamicMap.first,
           let last = dynamicMap.last {
            bounds += [first.time, last.time]
        }

        if applyTo.contains(.instrument),
           let first = instrumentTable.first,
           let last = instrumentTable.last {
            bounds += [first.time, last.time]
        }

        if applyTo.contains(.pan),
           let first = panMap.first,
           let last = panMap.last {
            bounds += [first.time, last.time]
        }

        guard let lowerBound = bounds.min(),
              let upperBound = bounds.max()
        else { return nil }

        return lowerBound...upperBound
    }

    // MARK: Private Instance Methods

    private func _dynamicEntryIDs(forNoteIDs noteIDs: Set<NoteID>?) -> Set<EntryID>? {
        guard let noteIDs
        else { return nil }

        guard let range = noteTable.selectedTimeRange(noteIDs: noteIDs)
        else { return [] }

        return Set(dynamicMap.filter { range.contains($0.time) }.map(\.entryID))
    }

    private func _instrumentEntryIDs(forNoteIDs noteIDs: Set<NoteID>?) -> Set<EntryID>? {
        guard let noteIDs
        else { return nil }

        guard let range = noteTable.selectedTimeRange(noteIDs: noteIDs)
        else { return [] }

        return Set(instrumentTable.filter { range.contains($0.time) }.map(\.entryID))
    }

    private func _panEntryIDs(forNoteIDs noteIDs: Set<NoteID>?) -> Set<EntryID>? {
        guard let noteIDs
        else { return nil }

        guard let range = noteTable.selectedTimeRange(noteIDs: noteIDs)
        else { return [] }

        return Set(panMap.filter { range.contains($0.time) }.map(\.entryID))
    }
}
