// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

extension Template {

    // MARK: Internal Nested Types

    //
    // The notes a template source takes of its part: strand by strand, in score order, and
    // merged into the one note table that analysis slices. Rests are where no chosen strand
    // sounds.
    //
    internal struct SourceNotes<TimeType: TimeProtocol, PitchType: PitchProtocol> {

        // MARK: Internal Initializers

        internal init(part: Part<TimeType, PitchType>,
                      selection: Work.PartSelection) {
            var isNoteSelection = false
            var noteTable = NoteTable<TimeType, PitchType>()
            var strands: [Strand<TimeType, PitchType>] = []

            for strand in part.strands {
                let strandSelection: Work.StrandSelection? = switch selection {
                case let .strands(strandSelections):
                    strandSelections[strand.strandID]

                case .whole:
                    .whole
                }

                guard let strandSelection
                else { continue }

                var chosen = strand

                if case let .notes(noteIDs) = strandSelection {
                    chosen.noteTable = strand.noteTable.partitioned(by: noteIDs).taken
                    isNoteSelection = true
                }

                noteTable.merge(with: chosen.noteTable)
                strands.append(chosen)
            }

            self.isNoteSelection = isNoteSelection
            self.noteTable = noteTable
            self.part = part
            self.strands = strands
        }

        // MARK: Internal Instance Properties

        //
        // Whether the source takes some of a strand's notes, rather than only whole strands.
        //
        internal let isNoteSelection: Bool

        //
        // Every chosen note, from every chosen strand, in time order.
        //
        internal let noteTable: NoteTable<TimeType, PitchType>

        internal let part: Part<TimeType, PitchType>

        //
        // The chosen strands, in score order, each holding only its chosen notes.
        //
        internal let strands: [Strand<TimeType, PitchType>]
    }
}

// MARK: -

extension Template.SourceNotes {

    // MARK: Internal Instance Properties

    //
    // The strand whose chosen notes start first, whose dynamic map and instrument table give the
    // source's starting dynamic and instrument: the first in score order on a tie, or when no
    // chosen strand has a note.
    //
    internal var leadingStrand: Strand<TimeType, PitchType> {
        let leading = strands.min { lhs, rhs in
            switch (lhs.noteTable.first?.attack, rhs.noteTable.first?.attack) {
            case let (lhsAttack?, rhsAttack?):
                lhsAttack < rhsAttack

            case (_?, nil):
                true

            default:
                false
            }
        }

        return leading ?? part.strands[0]
    }
}
