// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiTools

extension NoteTable {

    // MARK: Internal Nested Types

    internal struct Extractor {

        // MARK: Internal Initializers

        internal init(_ noteTable: NoteTable) {
            self.currentPairs = []
            self.currentTime = .zero
            self.noteReader = SequenceReader(noteTable.notes)
            self.noteSlices = []
        }

        // MARK: Private Nested Types

        private typealias Duration  = NoteTable.DurationType
        private typealias Note      = NoteTable.Note
        private typealias NotePair  = (tiedPitch: TiedPitch, duration: Duration)
        private typealias NoteSlice = NoteEvent<TimeType, PitchType>
        private typealias TiedPitch = NoteSlice.TiedPitch

        // MARK: Private Instance Properties

        private var currentPairs: [NotePair]
        private var currentTime: TimeType
        private var noteReader: SequenceReader<[Note]>
        private var noteSlices: [NoteSlice]
    }
}

// MARK: -

extension NoteTable.Extractor {

    // MARK: Internal Instance Methods

    internal mutating func extractNoteEvents() -> [NoteEvent<TimeType, PitchType>] {
        var slices: [NoteSlice] = []

        while _readNotePairs() {
            guard let duration = _durationOfNoteSlice()
            else { break }

            let slice = _removeNoteSlice(duration: duration)

            slices.append(slice)

            _advance(by: duration)
        }

        return slices
    }

    // MARK: Private Instance Methods

    private mutating func _advance(by duration: Duration) {
        guard let newTime = currentTime.moved(by: DirectedDuration(duration: duration,
                                                                   direction: .forward))
        else { fatalError("Bad logic!") }

        currentTime = newTime
    }

    private func _durationOfNoteSlice() -> Duration? {
        let dur1 = currentPairs.map { $0.duration }.min()
        let dur2 = _durationToNextAttack()

        guard let dur1,
              let dur2
        else { return dur1 ?? dur2 }

        return min(dur1, dur2)
    }

    private func _durationToNextAttack() -> Duration? {
        guard let nextNote = noteReader.peek(),
              let directedDuration = currentTime.duration(to: nextNote.attack),
              directedDuration.direction == .forward
        else { return nil }

        return directedDuration.duration
    }

    private mutating func _readNotePairs() -> Bool {
        guard noteReader.hasMore
        else { return !currentPairs.isEmpty }

        while let note = noteReader.peek() {
            guard note.attack == currentTime
            else { break }

            let tiedPitch = TiedPitch(pitch: note.startPitch)
            let notePair = (tiedPitch, note.duration)

            currentPairs.append(notePair)

            noteReader.skip()
        }

        return true
    }

    private mutating func _removeNoteSlice(duration: Duration) -> NoteSlice {
        guard !currentPairs.isEmpty
        else { return NoteSlice(duration: duration) }

        var tiedPitches: [TiedPitch] = []
        var updatedPairs: [NotePair] = []

        for pair in currentPairs {
            guard let remainingDuration = pair.duration.subtracting(duration)
            else { fatalError("Bad logic!") }

            let current = pair.tiedPitch
            let isTied = !remainingDuration.isZero

            let slicePitch = TiedPitch(pitch: current.pitch,
                                       beginsTie: isTied,
                                       endsTie: current.endsTie)

            tiedPitches.append(slicePitch)

            if isTied {
                let carryoverPitch = TiedPitch(pitch: current.pitch,
                                               endsTie: true)
                let carryoverPair = (carryoverPitch, remainingDuration)

                updatedPairs.append(carryoverPair)
            }
        }

        currentPairs = updatedPairs

        return NoteSlice(tiedPitches: tiedPitches,
                         duration: duration)
    }
}
