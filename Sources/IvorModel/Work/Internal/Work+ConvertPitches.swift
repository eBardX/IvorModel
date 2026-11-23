// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

extension Work {

    // MARK: Internal Type Methods

    //
    // `noteTable` with its pitches converted in one batch, by `convert`, in performance order
    // (see below). `nil` if a pitch can't be converted, unless `dropsUnconvertibleNotes` is set:
    // then an unconvertible main pitch drops its note, and an unconvertible grace or partner
    // pitch drops only its figure or ornament.
    //
    internal static func convertPitches<TimeType: TimeProtocol,
                                        FromPitchType: PitchProtocol,
                                        ToPitchType: PitchProtocol>(in noteTable: NoteTable<TimeType, FromPitchType>,
                                                                    using convert: ([FromPitchType]) -> [ToPitchType?],
                                                                    dropsUnconvertibleNotes: Bool) -> NoteTable<TimeType, ToPitchType>? {
        let oldNotes = noteTable.notes

        //
        // A context-aware pitch speller needs the part’s pitches in performance order: by onset,
        // then from low to high within a chord. A note with portamento contributes its end pitch
        // right after its start pitch. A note’s grace figure before it comes just before its own
        // pitches, its ornament’s written partner pitches just after them, and its figure after
        // it last.
        //
        let order = oldNotes.indices.sorted {
            (oldNotes[$0].attack, oldNotes[$0].startPitch) < (oldNotes[$1].attack, oldNotes[$1].startPitch)
        }

        var pitches: [FromPitchType] = []
        let empty = NotePositions(after: 0..<0, before: 0..<0, end: 0, partner: 0..<0, start: 0)
        var positions = Array(repeating: empty,
                              count: oldNotes.count)

        func append(_ newPitches: [FromPitchType]) -> Range<Int> {
            let lowerBound = pitches.count

            pitches.append(contentsOf: newPitches)

            return lowerBound..<pitches.count
        }

        for index in order {
            let note = oldNotes[index]
            let ornamentation = note.ornamentation

            positions[index].before = append(ornamentation?.graceBefore?.pitches ?? [])
            positions[index].start = pitches.count

            pitches.append(note.startPitch)

            if note.endPitch != note.startPitch {
                pitches.append(note.endPitch)
            }

            positions[index].end = pitches.count - 1
            positions[index].partner = append(ornamentation?.ornament?.pitches ?? [])
            positions[index].after = append(ornamentation?.graceAfter?.pitches ?? [])
        }

        let convertedPitches = convert(pitches)
        var notes: [NoteTable<TimeType, ToPitchType>.StoredNote] = []

        for (note, position) in zip(oldNotes, positions) {
            guard let startPitch = convertedPitches[position.start],
                  let endPitch = convertedPitches[position.end]
            else {
                if dropsUnconvertibleNotes { continue }

                return nil
            }

            guard let ornamentation = _converted(note.ornamentation,
                                                 convertedPitches: convertedPitches,
                                                 positions: position,
                                                 dropsUnconvertibleNotes: dropsUnconvertibleNotes)
            else { return nil }

            notes.append(NoteTable<TimeType, ToPitchType>.StoredNote(attack: note.attack,
                                                                     duration: note.duration,
                                                                     startPitch: startPitch,
                                                                     endPitch: endPitch,
                                                                     extras: note.extras,
                                                                     ornamentation: NoteTable.fittingPartner(ornamentation,
                                                                                                             startPitch: startPitch)))
        }

        return NoteTable(notes: notes)
    }

    // MARK: Private Type Aliases

    //
    // `.some` of a note's converted ornamentation (`.some(nil)` for none), or `nil` if the
    // conversion as a whole must fail.
    //
    private typealias ConvertedOrnamentation<TimeType: TimeProtocol, PitchType: PitchProtocol> = NoteOrnamentation<TimeType, PitchType>??
    private typealias NoteOrnamentation<TimeType: TimeProtocol, PitchType: PitchProtocol> = NoteTable<TimeType, PitchType>.Ornamentation

    // MARK: Private Type Methods

    //
    // A note's ornamentation carried into the new pitch type, each slot with its own converted
    // pitches (at `positions`, in the order the slot lists them). A slot with a pitch that
    // couldn't be converted is dropped on its own when `dropsUnconvertibleNotes` is set — the
    // note keeps its other slots — and otherwise fails the conversion: `nil`. `.some(nil)` for a
    // note with no ornamentation.
    //
    private static func _converted<TimeType: TimeProtocol,
                                   FromPitchType: PitchProtocol,
                                   ToPitchType: PitchProtocol>(_ ornamentation: NoteOrnamentation<TimeType, FromPitchType>?,
                                                               convertedPitches: [ToPitchType?],
                                                               positions: NotePositions,
                                                               dropsUnconvertibleNotes: Bool) -> ConvertedOrnamentation<TimeType, ToPitchType> {
        typealias Converter = NoteTable<TimeType, FromPitchType>.Converter<TimeType, ToPitchType>

        guard let ornamentation
        else { return .some(nil) }

        func converter(_ range: Range<Int>) -> Converter {
            var index = range.lowerBound

            return Converter(pitch: { _ in
                                 guard index < range.upperBound,
                                       let pitch = convertedPitches[index]
                                 else { throw ConversionFailure() }

                                 index += 1

                                 return pitch
                             },
                             duration: { $0 })
        }

        var failed = false

        func slot<Value, Result>(_ value: Value?,
                                 _ convert: (Value) throws -> Result) -> Result? {
            guard let value
            else { return nil }

            guard let result = try? convert(value)
            else { failed = true; return nil }

            return result
        }

        let noPitches = converter(0..<0)
        let graceBefore = slot(ornamentation.graceBefore, converter(positions.before).graceFigure)
        let graceAfter = slot(ornamentation.graceAfter, converter(positions.after).graceFigure)
        let ornament = slot(ornamentation.ornament, converter(positions.partner).ornament)
        let arpeggio = slot(ornamentation.arpeggio, noPitches.arpeggio)
        let fermata = slot(ornamentation.fermata, noPitches.fermataConverter.fermata)
        let result = NoteTable<TimeType, ToPitchType>.Ornamentation(graceBefore: graceBefore,
                                                                    graceAfter: graceAfter,
                                                                    ornament: ornament,
                                                                    arpeggio: arpeggio,
                                                                    fermata: fermata)

        guard !failed || dropsUnconvertibleNotes
        else { return nil }

        return .some(result)
    }
}
