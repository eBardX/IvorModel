// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiNumbers

extension Work {

    // MARK: Internal Type Methods

    //
    // `keyTable` with each entry's time mapped.
    //
    internal static func retimed(_ keyTable: KeyTable,
                                 by map: PositionMap) -> KeyTable {
        KeyTable(entries: keyTable.entries.map { entry in
            KeyTable.StoredEntry(entryID: entry.entryID,
                                 beatTime: _beatTime(map(entry.beatTime.numberValue, false)) ?? entry.beatTime,
                                 key: entry.key,
                                 extras: entry.extras)
        })
    }

    //
    // `meterTable` with each entry's time mapped, except one at time 0, which keeps its pickup.
    //
    internal static func retimed(_ meterTable: MeterTable,
                                 by map: PositionMap) -> MeterTable {
        let entries = meterTable.entries.map { entry in
            guard entry.beatTime > .zero
            else { return entry }

            return MeterTable.StoredEntry(entryID: entry.entryID,
                                          beatTime: _beatTime(map(entry.beatTime.numberValue, false)) ?? entry.beatTime,
                                          meter: entry.meter,
                                          extras: entry.extras)
        }

        return MeterTable(entries: entries,
                          pickup: meterTable.pickup)
    }

    //
    // `part` with every note, map entry, pedal entry and mark moved: a note's attack as an attack
    // and its release as a release, so a note sounding across an insertion lengthens.
    //
    internal static func retimed<TimeType: RenderableTime,
                                 PitchType: PitchProtocol>(_ part: Part<TimeType, PitchType>,
                                                           by map: @escaping PositionMap) -> Part<TimeType, PitchType> {
        let time = { (value: TimeType) -> TimeType in
            TimeType(number: map(value.number, false)) ?? value
        }
        func retimedNotes(_ noteTable: NoteTable<TimeType, PitchType>) -> NoteTable<TimeType, PitchType> {
            var notes: [NoteTable<TimeType, PitchType>.StoredNote] = []

            for note in noteTable.notes {
                guard let attack = TimeType(number: map(note.attack.number, false)),
                      let release = TimeType(number: map(note.release.number, true)),
                      let span = attack.duration(to: release),
                      span.direction == .forward
                else { notes.append(note); continue }

                notes.append(NoteTable<TimeType, PitchType>.StoredNote(noteID: note.noteID,
                                                                       attack: attack,
                                                                       duration: span.duration,
                                                                       startPitch: note.startPitch,
                                                                       endPitch: note.endPitch,
                                                                       extras: note.extras,
                                                                       ornamentation: note.ornamentation))
            }

            return NoteTable(notes: notes.sorted())
        }

        func retimedDynamics(_ dynamicMap: DynamicMap<TimeType>) -> DynamicMap<TimeType> {
            DynamicMap(defaultDynamic: dynamicMap.defaultDynamic,
                       entries: dynamicMap.entries.map {
                           DynamicMap.StoredEntry(entryID: $0.entryID, time: time($0.time), dynamic: $0.dynamic, extras: $0.extras)
                       })
        }

        func retimedInstruments(_ instrumentTable: InstrumentTable<TimeType>) -> InstrumentTable<TimeType> {
            InstrumentTable(defaultInstrument: instrumentTable.defaultInstrument,
                            entries: instrumentTable.entries.map {
                                InstrumentTable.StoredEntry(entryID: $0.entryID,
                                                            time: time($0.time),
                                                            instrument: $0.instrument,
                                                            extras: $0.extras)
                            })
        }

        var result = part

        result.strands = part.mappingStrands(noteTable: retimedNotes,
                                             instrumentTable: retimedInstruments,
                                             dynamicMap: retimedDynamics)
        result.dynamicMap = retimedDynamics(part.dynamicMap)
        result.instrumentTable = retimedInstruments(part.instrumentTable)
        result.panMap = PanMap(defaultPan: part.panMap.defaultPan,
                               entries: part.panMap.entries.map {
                                   PanMap.StoredEntry(entryID: $0.entryID, time: time($0.time), pan: $0.pan, extras: $0.extras)
                               })
        result.pedals = part.pedals.mapValues { $0.mapTimes(time) }
        result.markTable = part.markTable.convertedTimes(time)

        return result
    }

    //
    // `tempoMap` with each entry's time mapped, keeping their order, so a step stays a step.
    //
    internal static func retimed(_ tempoMap: TempoMap,
                                 by map: PositionMap) -> TempoMap {
        var result = TempoMap(defaultTempo: tempoMap.defaultTempo)

        for entry in tempoMap {
            result.insert(beatTime: _beatTime(map(entry.beatTime.numberValue, false)) ?? entry.beatTime,
                          tempo: entry.tempo,
                          extras: entry.extras)
        }

        return result
    }

    // MARK: Private Type Methods

    private static func _beatTime(_ number: Number) -> BeatTime? {
        BeatTime(numberValue: number)
    }
}
