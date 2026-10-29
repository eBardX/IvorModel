// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiTools

extension NoteTable {

    // MARK: Internal Nested Types

    //
    // The inverse of `Extractor`: writes note events back to back from time
    // zero, rejoining tied pitches into single notes. A pitch that ends a tie
    // extends the open note with the same pitch, if there is one; otherwise it
    // starts a new note. A broken tie never fails, it just becomes an ordinary
    // note boundary.
    //
    internal struct Assembler {

        // MARK: Internal Initializers

        internal init(noteEvents: [NoteEvent<TimeType, PitchType>]) {
            self.currentTime = .zero
            self.noteEvents = noteEvents
            self.noteTable = NoteTable()
            self.openNotes = []
        }

        // MARK: Private Type Aliases

        private typealias NoteSlice = NoteEvent<TimeType, PitchType>
        private typealias OpenNote  = (pitch: PitchType, attack: TimeType)

        // MARK: Private Instance Properties

        private let noteEvents: [NoteSlice]

        private var currentTime: TimeType
        private var noteTable: NoteTable
        private var openNotes: [OpenNote]
    }
}

// MARK: -

extension NoteTable.Assembler {

    // MARK: Internal Instance Methods

    internal mutating func assembleNoteTable() -> NoteTable {
        for noteEvent in noteEvents {
            _append(noteEvent)
        }

        //
        // Close every note still open at the end:
        //
        for openNote in openNotes {
            _insertNote(openNote,
                        releasedAt: currentTime)
        }

        openNotes = []

        return noteTable
    }

    // MARK: Private Instance Methods

    private mutating func _append(_ noteEvent: NoteSlice) {
        let releaseTime = currentTime.moved(by: DirectedDuration(duration: noteEvent.duration,
                                                                 direction: .forward)).require()

        var stillOpenNotes: [OpenNote] = []
        var unmatchedNotes = openNotes

        for tiedPitch in noteEvent.tiedPitches {
            var attack = currentTime

            if tiedPitch.endsTie,
               let index = unmatchedNotes.firstIndex(where: { $0.pitch == tiedPitch.pitch }) {
                attack = unmatchedNotes.remove(at: index).attack
            }

            let note = (pitch: tiedPitch.pitch, attack: attack)

            if tiedPitch.startsTie {
                stillOpenNotes.append(note)
            } else {
                _insertNote(note,
                            releasedAt: releaseTime)
            }
        }

        //
        // An open note that this event doesn’t continue closes where it stands:
        //
        for unmatchedNote in unmatchedNotes {
            _insertNote(unmatchedNote,
                        releasedAt: currentTime)
        }

        currentTime = releaseTime
        openNotes = stillOpenNotes
    }

    private mutating func _insertNote(_ note: OpenNote,
                                      releasedAt releaseTime: TimeType) {
        noteTable.insert(attack: note.attack,
                         duration: note.attack.duration(to: releaseTime).require().duration,
                         pitch: note.pitch)
    }
}
