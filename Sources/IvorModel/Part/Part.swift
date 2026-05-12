public import IvorTiming
public import IvorTuning

public struct Part<TimeType: TimeProtocol, PitchType: PitchProtocol> {

    // MARK: Public Initializers

    public init(name: String,
                noteTable: NoteTable<TimeType, PitchType>? = nil,
                loudnessMap: LoudnessMap<TimeType>? = nil,
                instrumentMap: InstrumentMap<TimeType>? = nil,
                positionMap: PositionMap<TimeType>? = nil) {
        self.instrumentMap = instrumentMap ?? InstrumentMap()
        self.loudnessMap = loudnessMap ?? LoudnessMap()
        self.name = name
        self.noteTable = noteTable ?? NoteTable()
        self.positionMap = positionMap ?? PositionMap()
    }

    // MARK: Public Instance Properties

    public var instrumentMap: InstrumentMap<TimeType>
    public var loudnessMap: LoudnessMap<TimeType>
    public var name: String
    public var noteTable: NoteTable<TimeType, PitchType>
    public var positionMap: PositionMap<TimeType>

    public var timeRange: ClosedRange<TimeType> {
        noteTable.timeRange
    }
}

// MARK: - Codable

extension Part: Codable {

    // MARK: Public Initializers

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let instrumentMap = try container.decode(InstrumentMap<TimeType>.self,
                                                 forKey: .instrumentMap)

        let loudnessMap = try container.decode(LoudnessMap<TimeType>.self,
                                               forKey: .loudnessMap)

        let name = try container.decode(String.self,
                                        forKey: .name)

        let noteTable = try container.decode(NoteTable<TimeType, PitchType>.self,
                                             forKey: .noteTable)

        let positionMap = try container.decode(PositionMap<TimeType>.self,
                                               forKey: .positionMap)

        self.init(name: name,
                  noteTable: noteTable,
                  loudnessMap: loudnessMap,
                  instrumentMap: instrumentMap,
                  positionMap: positionMap)
    }

    // MARK: Public Instance Methods

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(name,
                             forKey: .name)

        try container.encode(noteTable,
                             forKey: .noteTable)

        try container.encode(loudnessMap,
                             forKey: .loudnessMap)

        try container.encode(instrumentMap,
                             forKey: .instrumentMap)

        try container.encode(positionMap,
                             forKey: .positionMap)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case instrumentMap
        case loudnessMap
        case name
        case noteTable
        case positionMap
    }
}

// MARK: - Sendable

extension Part: Sendable {
}
