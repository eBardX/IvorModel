// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Work {

    // MARK: Public Nested Types

    /// A note event extracted from a work, tagged with its originating part and absolute attack
    /// time.
    public struct TaggedNoteEvent<TimeType: TimeProtocol, PitchType: PitchProtocol> {

        // MARK: Public Initializers

        /// Creates a tagged note event.
        ///
        /// - Parameter partID:      The ID of the part this event was extracted from.
        /// - Parameter attack:      The absolute attack time of this event.
        /// - Parameter noteEvent:   The underlying note event.
        public init(partID: PartID,
                    attack: TimeType,
                    noteEvent: NoteEvent<TimeType, PitchType>) {
            self.attack = attack
            self.noteEvent = noteEvent
            self.partID = partID
        }

        // MARK: Public Instance Properties

        /// The absolute attack time of this event.
        public let attack: TimeType

        /// The underlying note event.
        public let noteEvent: NoteEvent<TimeType, PitchType>

        /// The ID of the part this event was extracted from.
        public let partID: PartID
    }
}

// MARK: - Equatable

extension Work.TaggedNoteEvent: Equatable {
}

// MARK: - Sendable

extension Work.TaggedNoteEvent: Sendable {
}
