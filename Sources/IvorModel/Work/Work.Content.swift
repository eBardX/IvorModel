// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Work {

    // MARK: Public Nested Types

    /// The musical content of a work: its parts, with their pitch notation and time basis, and in
    /// beat time a tempo map, a meter table and a key table.
    ///
    /// The content holds a ``Work/Body`` with its concrete types. Read it through ``body`` with
    /// a generic function to handle every kind of content alike, or through ``cases`` to handle
    /// each kind in its own way. Make content with the static methods named after the cases,
    /// such as ``standardBeat(_:_:_:_:)``, or ``empty(timeBasis:pitchNotation:)``.
    public struct Content {

        // MARK: Internal Initializers

        internal init(body: any Work.Body) {
            self.body = body
        }

        // MARK: Public Instance Properties

        /// The content’s parts, and whatever else its time basis carries, with their concrete
        /// types.
        ///
        /// Content changes only through ``Work``’s own methods, which keep the rules a work
        /// keeps, so the body can be read here but not replaced.
        public internal(set) var body: any Work.Body
    }
}

// MARK: -

extension Work.Content {

    // MARK: Public Type Methods

    /// Returns beat-time content in absolute (frequency) pitch notation.
    ///
    /// - Parameter parts:      The parts, in score order.
    /// - Parameter tempoMap:   The tempo map.
    /// - Parameter meterTable: The meter table.
    /// - Parameter keyTable:   The key table.
    ///
    /// - Returns:  The content.
    public static func absoluteBeat(_ parts: [Part<BeatTime, Frequency>],
                                    _ tempoMap: TempoMap,
                                    _ meterTable: MeterTable,
                                    _ keyTable: KeyTable) -> Self {
        Self(body: Work.BeatBody(parts: parts,
                                 tempoMap: tempoMap,
                                 meterTable: meterTable,
                                 keyTable: keyTable))
    }

    /// Returns wall-time content in absolute (frequency) pitch notation.
    ///
    /// - Parameter parts:  The parts, in score order.
    ///
    /// - Returns:  The content.
    public static func absoluteWall(_ parts: [Part<WallTime, Frequency>]) -> Self {
        Self(body: Work.WallBody(parts: parts))
    }

    /// Returns content with no parts in the given time basis and pitch notation.
    ///
    /// Beat-time content gets an empty tempo map with the default tempo, an empty meter table and
    /// an empty key table.
    ///
    /// - Parameter timeBasis:      The time basis of the content.
    /// - Parameter pitchNotation:  The pitch notation of the content.
    ///
    /// - Returns:  Empty ``Work/Content`` of the matching kind.
    public static func empty(timeBasis: TimeBasis,
                             pitchNotation: PitchNotation) -> Self {
        switch (pitchNotation, timeBasis) {
        case (.absolute, .beat):
            Self(body: Work.BeatBody<Frequency>())

        case (.absolute, .wall):
            Self(body: Work.WallBody<Frequency>())

        case (.keyboard, .beat):
            Self(body: Work.BeatBody<NoteNumber>())

        case (.keyboard, .wall):
            Self(body: Work.WallBody<NoteNumber>())

        case (.standard, .beat):
            Self(body: Work.BeatBody<Pitch>())

        case (.standard, .wall):
            Self(body: Work.WallBody<Pitch>())
        }
    }

    /// Returns beat-time content in keyboard (MIDI note number) pitch notation.
    ///
    /// - Parameter parts:      The parts, in score order.
    /// - Parameter tempoMap:   The tempo map.
    /// - Parameter meterTable: The meter table.
    /// - Parameter keyTable:   The key table.
    ///
    /// - Returns:  The content.
    public static func keyboardBeat(_ parts: [Part<BeatTime, NoteNumber>],
                                    _ tempoMap: TempoMap,
                                    _ meterTable: MeterTable,
                                    _ keyTable: KeyTable) -> Self {
        Self(body: Work.BeatBody(parts: parts,
                                 tempoMap: tempoMap,
                                 meterTable: meterTable,
                                 keyTable: keyTable))
    }

    /// Returns wall-time content in keyboard (MIDI note number) pitch notation.
    ///
    /// - Parameter parts:  The parts, in score order.
    ///
    /// - Returns:  The content.
    public static func keyboardWall(_ parts: [Part<WallTime, NoteNumber>]) -> Self {
        Self(body: Work.WallBody(parts: parts))
    }

    /// Returns beat-time content in standard (staff) pitch notation.
    ///
    /// - Parameter parts:      The parts, in score order.
    /// - Parameter tempoMap:   The tempo map.
    /// - Parameter meterTable: The meter table.
    /// - Parameter keyTable:   The key table.
    ///
    /// - Returns:  The content.
    public static func standardBeat(_ parts: [Part<BeatTime, Pitch>],
                                    _ tempoMap: TempoMap,
                                    _ meterTable: MeterTable,
                                    _ keyTable: KeyTable) -> Self {
        Self(body: Work.BeatBody(parts: parts,
                                 tempoMap: tempoMap,
                                 meterTable: meterTable,
                                 keyTable: keyTable))
    }

    /// Returns wall-time content in standard (staff) pitch notation.
    ///
    /// - Parameter parts:  The parts, in score order.
    ///
    /// - Returns:  The content.
    public static func standardWall(_ parts: [Part<WallTime, Pitch>]) -> Self {
        Self(body: Work.WallBody(parts: parts))
    }

    // MARK: Public Instance Properties

    /// The content as one of six cases, one for each pitch notation and time basis.
    public var cases: Cases {
        switch body {
        case let body as Work.BeatBody<Frequency>:
            .absoluteBeat(body.parts, body.tempoMap, body.meterTable, body.keyTable)

        case let body as Work.WallBody<Frequency>:
            .absoluteWall(body.parts)

        case let body as Work.BeatBody<NoteNumber>:
            .keyboardBeat(body.parts, body.tempoMap, body.meterTable, body.keyTable)

        case let body as Work.WallBody<NoteNumber>:
            .keyboardWall(body.parts)

        case let body as Work.BeatBody<Pitch>:
            .standardBeat(body.parts, body.tempoMap, body.meterTable, body.keyTable)

        case let body as Work.WallBody<Pitch>:
            .standardWall(body.parts)

        default:
            //
            // Content is made only by this type's own methods and decoding, each of which makes
            // one of the six bodies above.
            //
            preconditionFailure("Unexpected work body: \(type(of: body))")
        }
    }

    /// The pitch notation of the content.
    public var pitchNotation: PitchNotation {
        body.pitchNotation
    }

    /// The time basis of the content.
    public var timeBasis: TimeBasis {
        body.timeBasis
    }

    // MARK: Internal Instance Properties

    //
    // The arpeggio groups any part's notes belong to.
    //
    internal var arpeggioGroups: Set<ArpeggioGroup> {
        body.arpeggioGroups
    }

    //
    // The first note ID that more than one note shares, in any parts, or `nil` if every note's is
    // distinct.
    //
    internal var firstDuplicateNoteID: NoteID? {
        var seen: Set<NoteID> = []

        return body.noteIDs.first { !seen.insert($0).inserted }
    }

    //
    // The first part ID that more than one part shares, or `nil` if every part's is distinct.
    //
    internal var firstDuplicatePartID: PartID? {
        var seen: Set<PartID> = []

        return body.partIDs.first { !seen.insert($0).inserted }
    }

    //
    // The first rule this content breaks, as the error that reports it, or `nil` if it keeps them
    // all: distinct part IDs, then distinct note IDs. Every way content gets into a work checks
    // this — replacing it, a `modifyPart` body, decoding — so a work always keeps the rules.
    //
    internal var invariantError: Work.Error? {
        if let partID = firstDuplicatePartID {
            return .duplicatePartID(partID)
        }

        if let noteID = firstDuplicateNoteID {
            return .duplicateNoteID(noteID)
        }

        return nil
    }

    //
    // The ID of every note of every part, in part order.
    //
    internal var noteIDs: [NoteID] {
        body.noteIDs
    }

    internal var partIDs: [PartID] {
        body.partIDs
    }
}

// MARK: - Codable

extension Work.Content: Codable {

    // MARK: Public Initializers

    /// Creates a work content value by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let pitchNotation = try container.decode(PitchNotation.self,
                                                 forKey: .pitchNotation)

        let timeBasis = try container.decode(TimeBasis.self,
                                             forKey: .timeBasis)

        switch (pitchNotation, timeBasis) {
        case (.absolute, .beat):
            self = try Self(body: Self._decodeBeatBody(Work.BeatBody<Frequency>.self, from: container))

        case (.absolute, .wall):
            self = try Self(body: Self._decodeWallBody(Work.WallBody<Frequency>.self, from: container))

        case (.keyboard, .beat):
            self = try Self(body: Self._decodeBeatBody(Work.BeatBody<NoteNumber>.self, from: container))

        case (.keyboard, .wall):
            self = try Self(body: Self._decodeWallBody(Work.WallBody<NoteNumber>.self, from: container))

        case (.standard, .beat):
            self = try Self(body: Self._decodeBeatBody(Work.BeatBody<Pitch>.self, from: container))

        case (.standard, .wall):
            self = try Self(body: Self._decodeWallBody(Work.WallBody<Pitch>.self, from: container))
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this work content into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(pitchNotation,
                             forKey: .pitchNotation)

        try container.encode(timeBasis,
                             forKey: .timeBasis)

        try Self._encodeParts(of: body,
                              into: &container)

        if let body = body as? any Work.BeatTimeBody {
            try container.encode(body.tempoMap,
                                 forKey: .tempoMap)

            try container.encode(body.meterTable,
                                 forKey: .meterTable)

            try container.encode(body.keyTable,
                                 forKey: .keyTable)
        }
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case keyTable
        case meterTable
        case parts
        case pitchNotation
        case tempoMap
        case timeBasis
    }

    // MARK: Private Type Methods

    private static func _decodeBeatBody<PitchType>(_ type: Work.BeatBody<PitchType>.Type,
                                                   from container: KeyedDecodingContainer<CodingKeys>) throws -> Work.BeatBody<PitchType> {
        try Work.BeatBody(parts: container.decode([Part<BeatTime, PitchType>].self,
                                                  forKey: .parts),
                          tempoMap: container.decode(TempoMap.self,
                                                     forKey: .tempoMap).normalizingExtraNames(),
                          meterTable: container.decode(MeterTable.self,
                                                       forKey: .meterTable),
                          keyTable: container.decode(KeyTable.self,
                                                     forKey: .keyTable))
    }

    private static func _decodeWallBody<PitchType>(_ type: Work.WallBody<PitchType>.Type,
                                                   from container: KeyedDecodingContainer<CodingKeys>) throws -> Work.WallBody<PitchType> {
        try Work.WallBody(parts: container.decode([Part<WallTime, PitchType>].self,
                                                  forKey: .parts))
    }

    private static func _encodeParts(of body: some Work.Body,
                                     into container: inout KeyedEncodingContainer<CodingKeys>) throws {
        try container.encode(body.parts,
                             forKey: .parts)
    }
}

// MARK: - Sendable

extension Work.Content: Sendable {
}
