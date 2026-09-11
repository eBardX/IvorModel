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
    ///                         resolves to the note table’s own range, or — when `noteIDs` is
    ///                         non-`nil` — the selected notes’ own range.
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
                                 applyTo: MapTargets = .all) throws(Error) {
        var newNoteTable = noteTable

        do {
            try newNoteTable.augment(by: factor,
                                     anchor: anchor,
                                     noteIDs: noteIDs)
        } catch {
            throw Error.noteTableFailure(error)
        }

        var newDynamicMap = dynamicMap
        var newInstrumentMap = instrumentMap
        var newPanMap = panMap

        if applyTo.contains(.dynamic) {
            do {
                try newDynamicMap.augment(by: factor,
                                          anchor: anchor,
                                          entryIDs: _dynamicEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.dynamicMapFailure(error)
            }
        }

        if applyTo.contains(.instrument) {
            do {
                try newInstrumentMap.augment(by: factor,
                                             anchor: anchor,
                                             entryIDs: _instrumentEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.instrumentMapFailure(error)
            }
        }

        if applyTo.contains(.pan) {
            do {
                try newPanMap.augment(by: factor,
                                      anchor: anchor,
                                      entryIDs: _panEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.panMapFailure(error)
            }
        }

        noteTable = newNoteTable
        dynamicMap = newDynamicMap
        instrumentMap = newInstrumentMap
        panMap = newPanMap
    }

    /// Diminishes note attack times and durations by a rational factor, along with any
    /// parameter maps selected by `applyTo`.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to compress the selected note
    ///                         timings.
    /// - Parameter anchor:     The low time bound to compress attack times relative to. `nil`
    ///                         resolves to the note table’s own range, or — when `noteIDs` is
    ///                         non-`nil` — the selected notes’ own range.
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
                                  applyTo: MapTargets = .all) throws(Error) {
        var newNoteTable = noteTable

        do {
            try newNoteTable.diminish(by: factor,
                                      anchor: anchor,
                                      noteIDs: noteIDs)
        } catch {
            throw Error.noteTableFailure(error)
        }

        var newDynamicMap = dynamicMap
        var newInstrumentMap = instrumentMap
        var newPanMap = panMap

        if applyTo.contains(.dynamic) {
            do {
                try newDynamicMap.diminish(by: factor,
                                           anchor: anchor,
                                           entryIDs: _dynamicEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.dynamicMapFailure(error)
            }
        }

        if applyTo.contains(.instrument) {
            do {
                try newInstrumentMap.diminish(by: factor,
                                              anchor: anchor,
                                              entryIDs: _instrumentEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.instrumentMapFailure(error)
            }
        }

        if applyTo.contains(.pan) {
            do {
                try newPanMap.diminish(by: factor,
                                       anchor: anchor,
                                       entryIDs: _panEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.panMapFailure(error)
            }
        }

        noteTable = newNoteTable
        dynamicMap = newDynamicMap
        instrumentMap = newInstrumentMap
        panMap = newPanMap
    }

    /// Inverts note pitches around a pitch range.
    ///
    /// - Parameter pitchRange:   The pitch range to invert pitches around. `nil` resolves to the
    ///                           note table’s own pitch range, or — when `noteIDs` is non-`nil` —
    ///                           the selected notes’ own pitch range.
    /// - Parameter noteIDs:      The identities of the notes to invert, or `nil` to invert every
    ///                           note in the note table.
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
                              applyTo: MapTargets = .all) throws(Error) {
        var newNoteTable = noteTable

        do {
            try newNoteTable.move(by: directedDuration,
                                  noteIDs: noteIDs)
        } catch {
            throw Error.noteTableFailure(error)
        }

        var newDynamicMap = dynamicMap
        var newInstrumentMap = instrumentMap
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
                try newInstrumentMap.move(by: directedDuration,
                                          entryIDs: _instrumentEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.instrumentMapFailure(error)
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
        instrumentMap = newInstrumentMap
        panMap = newPanMap
    }

    /// Reverses the order of notes within a time range, along with any parameter maps selected
    /// by `applyTo`.
    ///
    /// - Parameter timeRange:   The time range to mirror attack times around. `nil` resolves to
    ///                          the note table’s own time range, or — when `noteIDs` is
    ///                          non-`nil` — the selected notes’ own time range.
    /// - Parameter noteIDs:     The identities of the notes to reverse, or `nil` to reverse every
    ///                          note in the note table. Also narrows which entries of any map
    ///                          selected by `applyTo` are carried along, to those falling within
    ///                          the selected notes’ own time range.
    /// - Parameter applyTo:     The parameter maps to reverse along with the note table.
    ///                          Defaults to every map.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` if the note table cannot be reversed, or
    ///             the corresponding map-failure case if a selected map cannot be reversed.
    public mutating func reverse(within timeRange: ClosedRange<TimeType>? = nil,
                                 noteIDs: Set<NoteID>? = nil,
                                 applyTo: MapTargets = .all) throws(Error) {
        var newNoteTable = noteTable

        do {
            try newNoteTable.reverse(within: timeRange,
                                     noteIDs: noteIDs)
        } catch {
            throw Error.noteTableFailure(error)
        }

        var newDynamicMap = dynamicMap
        var newInstrumentMap = instrumentMap
        var newPanMap = panMap

        if applyTo.contains(.dynamic) {
            do {
                try newDynamicMap.reverse(within: timeRange,
                                          entryIDs: _dynamicEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.dynamicMapFailure(error)
            }
        }

        if applyTo.contains(.instrument) {
            do {
                try newInstrumentMap.reverse(within: timeRange,
                                             entryIDs: _instrumentEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.instrumentMapFailure(error)
            }
        }

        if applyTo.contains(.pan) {
            do {
                try newPanMap.reverse(within: timeRange,
                                      entryIDs: _panEntryIDs(forNoteIDs: noteIDs))
            } catch {
                throw Error.panMapFailure(error)
            }
        }

        noteTable = newNoteTable
        dynamicMap = newDynamicMap
        instrumentMap = newInstrumentMap
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

    // MARK: Private Instance Methods

    //
    // `noteIDs` of `nil` means "every note", so the map should likewise carry no restriction —
    // `nil` entryIDs, not the (possibly empty) derived set below. Only a concrete selection
    // narrows the map, to entries whose time falls within that selection's own resolved range —
    // the same range `NoteTable`'s own anchor/reverse logic (Phase 1) resolves for it, reused
    // here rather than recomputed. A selection whose own range comes back `nil` (an empty or
    // unmatched `noteIDs`) narrows the map to no entries at all, rather than falling back to
    // every entry.
    //
    private func _dynamicEntryIDs(forNoteIDs noteIDs: Set<NoteID>?) -> Set<DynamicMap<TimeType>.EntryID>? {
        guard let noteIDs
        else { return nil }

        guard let range = noteTable.selectedTimeRange(noteIDs: noteIDs)
        else { return [] }

        var entryIDs: Set<DynamicMap<TimeType>.EntryID> = []

        dynamicMap.forEach { entryID, time, _, _ in
            if range.contains(time) {
                entryIDs.insert(entryID)
            }
        }

        return entryIDs
    }

    private func _instrumentEntryIDs(forNoteIDs noteIDs: Set<NoteID>?) -> Set<InstrumentMap<TimeType>.EntryID>? {
        guard let noteIDs
        else { return nil }

        guard let range = noteTable.selectedTimeRange(noteIDs: noteIDs)
        else { return [] }

        var entryIDs: Set<InstrumentMap<TimeType>.EntryID> = []

        instrumentMap.forEach { entryID, time, _, _ in
            if range.contains(time) {
                entryIDs.insert(entryID)
            }
        }

        return entryIDs
    }

    private func _panEntryIDs(forNoteIDs noteIDs: Set<NoteID>?) -> Set<PanMap<TimeType>.EntryID>? {
        guard let noteIDs
        else { return nil }

        guard let range = noteTable.selectedTimeRange(noteIDs: noteIDs)
        else { return [] }

        var entryIDs: Set<PanMap<TimeType>.EntryID> = []

        panMap.forEach { entryID, time, _, _ in
            if range.contains(time) {
                entryIDs.insert(entryID)
            }
        }

        return entryIDs
    }
}
