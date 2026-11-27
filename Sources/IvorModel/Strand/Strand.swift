// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiTools

/// One strand of notes in a ``Part``: a line, or a texture, the composer reasons about on its
/// own, such as a pianist’s right hand, an organ’s pedals, or one half of a *divisi*.
///
/// A part is what one performer (or one unison section) plays; its strands divide its notes,
/// and say nothing about how they are written down. A strand uses its part’s instrument table
/// and dynamic map unless it has its own, in which case its own replaces the part’s for its
/// notes. Everything else a performer controls as a whole — pan, pedals, marks — belongs to the
/// part.
public struct Strand<TimeType: TimeProtocol, PitchType: PitchProtocol> {

    // MARK: Public Initializers

    /// Creates a strand with a fresh ``StrandID``.
    ///
    /// - Parameter name:               The display name of the strand; empty for an unnamed one.
    ///                                 Defaults to empty. Its whitespace is normalized to a single
    ///                                 line.
    /// - Parameter noteTable:          The strand’s notes. Defaults to none.
    /// - Parameter instrumentTable:    The strand’s own instrument table, or `nil` to use its
    ///                                 part’s. Defaults to `nil`.
    /// - Parameter dynamicMap:         The strand’s own dynamic map, or `nil` to use its part’s.
    ///                                 Defaults to `nil`.
    /// - Parameter extras:             Extra data for the strand. Defaults to `nil`; empty extras
    ///                                 are stored as `nil`.
    public init(name: String = "",
                noteTable: NoteTable<TimeType, PitchType> = NoteTable(),
                instrumentTable: InstrumentTable<TimeType>? = nil,
                dynamicMap: DynamicMap<TimeType>? = nil,
                extras: Extras? = nil) {
        self.init(strandID: StrandID(),
                  name: name,
                  noteTable: noteTable,
                  instrumentTable: instrumentTable,
                  dynamicMap: dynamicMap,
                  extras: extras)
    }

    // MARK: Public Instance Properties

    /// The unique ID of this strand.
    public let strandID: StrandID

    /// The strand’s own dynamic map, which replaces its part’s for its notes, or `nil` if it uses
    /// its part’s.
    public var dynamicMap: DynamicMap<TimeType>?

    /// Extra data for the strand, or `nil` if it has none. Empty extras are stored as `nil`.
    public var extras: Extras? {
        didSet { extras = Self._normalized(extras) }
    }

    /// The strand’s own instrument table, which replaces its part’s for its notes, or `nil` if it
    /// uses its part’s.
    public var instrumentTable: InstrumentTable<TimeType>?

    /// The display name of the strand, with whitespace normalized to a single line; empty for an
    /// unnamed strand.
    public var name: String {
        didSet { name = name.normalizingWhitespace() }
    }

    /// The strand’s notes.
    public var noteTable: NoteTable<TimeType, PitchType>

    // MARK: Internal Initializers

    //
    // Keeps an existing identity: for decoding, and for the conversions that rebuild a strand
    // with new content but must leave it the same strand.
    //
    internal init(strandID: StrandID,
                  name: String,
                  noteTable: NoteTable<TimeType, PitchType>,
                  instrumentTable: InstrumentTable<TimeType>?,
                  dynamicMap: DynamicMap<TimeType>?,
                  extras: Extras?) {
        self.dynamicMap = dynamicMap
        self.extras = Self._normalized(extras)
        self.instrumentTable = instrumentTable
        //
        // `didSet` doesn't run during initialization, so normalize here too:
        //
        self.name = name.normalizingWhitespace()
        self.noteTable = noteTable
        self.strandID = strandID
    }
}

// MARK: -

extension Strand {

    // MARK: Public Instance Methods

    /// Returns a copy of this strand with the same content but a fresh ``StrandID``, and its notes
    /// under fresh identities, so the copy can join the original in one work.
    public func duplicated() -> Self {
        Self(name: name,
             noteTable: noteTable.renewingNoteIDs(),
             instrumentTable: instrumentTable,
             dynamicMap: dynamicMap,
             extras: extras)
    }

    // MARK: Internal Instance Methods

    //
    // This strand, keeping its identity, name, own tables and extras, with `noteTable` in place
    // of its notes.
    //
    internal func replacingNoteTable<NewTime, NewPitch>(with noteTable: NoteTable<NewTime, NewPitch>,
                                                        instrumentTable: InstrumentTable<NewTime>?,
                                                        dynamicMap: DynamicMap<NewTime>?) -> Strand<NewTime, NewPitch> {
        Strand<NewTime, NewPitch>(strandID: strandID,
                                  name: name,
                                  noteTable: noteTable,
                                  instrumentTable: instrumentTable,
                                  dynamicMap: dynamicMap,
                                  extras: extras)
    }

    // MARK: Private Type Methods

    private static func _normalized(_ extras: Extras?) -> Extras? {
        extras?.isEmpty ?? true ? nil : extras
    }
}

// MARK: - Codable

extension Strand: Codable {

    // MARK: Public Initializers

    /// Creates a strand by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try self.init(strandID: container.decode(StrandID.self,
                                                 forKey: .strandID),
                      name: container.decode(String.self,
                                             forKey: .name),
                      noteTable: container.decode(NoteTable<TimeType, PitchType>.self,
                                                  forKey: .noteTable),
                      instrumentTable: container.decodeIfPresent(InstrumentTable<TimeType>.self,
                                                                 forKey: .instrumentTable),
                      dynamicMap: container.decodeIfPresent(DynamicMap<TimeType>.self,
                                                            forKey: .dynamicMap),
                      extras: container.decodeIfPresent(Extras.self,
                                                        forKey: .extras)?.normalizingNames())
    }

    // MARK: Public Instance Methods

    /// Encodes this strand into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(strandID,
                             forKey: .strandID)

        try container.encode(name,
                             forKey: .name)

        try container.encode(noteTable,
                             forKey: .noteTable)

        try container.encodeIfPresent(instrumentTable,
                                      forKey: .instrumentTable)

        try container.encodeIfPresent(dynamicMap,
                                      forKey: .dynamicMap)

        try container.encodeIfPresent(extras,
                                      forKey: .extras)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case dynamicMap
        case extras
        case instrumentTable
        case name
        case noteTable
        case strandID
    }
}

// MARK: - Sendable

extension Strand: Sendable {
}
