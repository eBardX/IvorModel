// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

/// A named musical part containing a note table and associated performance maps.
public struct Part<TimeType: TimeProtocol, PitchType: PitchProtocol> {

    // MARK: Public Initializers

    /// Creates a part with the given name and optional performance data.
    ///
    /// - Parameter name:           The display name of the part.
    /// - Parameter noteTable:      The note table for the part. Defaults to an
    ///                             empty note table.
    /// - Parameter dynamicMap:     The dynamic map for the part. Defaults to
    ///                             an empty dynamic map.
    /// - Parameter instrumentMap:  The instrument map for the part. Defaults to
    ///                             an empty instrument map.
    /// - Parameter panMap:         The pan map for the part. Defaults to an
    ///                             empty pan map.
    public init(name: String,
                noteTable: NoteTable<TimeType, PitchType>? = nil,
                dynamicMap: DynamicMap<TimeType>? = nil,
                instrumentMap: InstrumentMap<TimeType>? = nil,
                panMap: PanMap<TimeType>? = nil) {
        self.dynamicMap = dynamicMap ?? DynamicMap()
        self.instrumentMap = instrumentMap ?? InstrumentMap()
        self.name = name
        self.noteTable = noteTable ?? NoteTable()
        self.panMap = panMap ?? PanMap()
    }

    // MARK: Public Instance Properties

    /// The dynamic map for this part.
    public var dynamicMap: DynamicMap<TimeType>

    /// The instrument map for this part.
    public var instrumentMap: InstrumentMap<TimeType>

    /// The display name of this part.
    public var name: String

    /// The note table for this part.
    public var noteTable: NoteTable<TimeType, PitchType>

    /// The pan map for this part.
    public var panMap: PanMap<TimeType>

    /// The time range spanned by the notes in this part, or `nil` if the part is empty.
    public var timeRange: ClosedRange<TimeType>? {
        noteTable.timeRange
    }
}

// MARK: - Codable

extension Part: Codable {

    // MARK: Public Initializers

    /// Creates a part by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let dynamicMap = try container.decode(DynamicMap<TimeType>.self,
                                              forKey: .dynamicMap)

        let instrumentMap = try container.decode(InstrumentMap<TimeType>.self,
                                                 forKey: .instrumentMap)

        let name = try container.decode(String.self,
                                        forKey: .name)

        let noteTable = try container.decode(NoteTable<TimeType, PitchType>.self,
                                             forKey: .noteTable)

        let panMap = try container.decode(PanMap<TimeType>.self,
                                          forKey: .panMap)

        self.init(name: name,
                  noteTable: noteTable,
                  dynamicMap: dynamicMap,
                  instrumentMap: instrumentMap,
                  panMap: panMap)
    }

    // MARK: Public Instance Methods

    /// Encodes this part into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(name,
                             forKey: .name)

        try container.encode(noteTable,
                             forKey: .noteTable)

        try container.encode(dynamicMap,
                             forKey: .dynamicMap)

        try container.encode(instrumentMap,
                             forKey: .instrumentMap)

        try container.encode(panMap,
                             forKey: .panMap)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case dynamicMap
        case instrumentMap
        case name
        case noteTable
        case panMap
    }
}

// MARK: - Sendable

extension Part: Sendable {
}
