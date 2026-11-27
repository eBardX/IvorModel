// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiTools

/// A named musical part containing a note table, its parameter maps, its instrument table, its
/// dictionary of pedal tables, its mark table, and its interpretation rules.
public struct Part<TimeType: TimeProtocol, PitchType: PitchProtocol> {

    // MARK: Public Type Aliases

    /// The duration type associated with the time type.
    public typealias DurationType = TimeType.DurationType

    /// The interval type associated with the pitch type.
    public typealias IntervalType = PitchType.IntervalType

    // MARK: Public Initializers

    /// Creates a part with the given name and optional note, map, instrument, pedal and mark data,
    /// interpretation rules, and extras.
    ///
    /// - Parameter name:               The display name of the part. Its whitespace is
    ///                                 normalized to a single line.
    /// - Parameter noteTable:          The note table for the part. Defaults to an
    ///                                 empty note table.
    /// - Parameter dynamicMap:         The dynamic map for the part. Defaults to
    ///                                 an empty dynamic map.
    /// - Parameter instrumentTable:    The instrument table for the part. Defaults to
    ///                                 an empty instrument table.
    /// - Parameter panMap:             The pan map for the part. Defaults to an
    ///                                 empty pan map.
    /// - Parameter pedals:             The dictionary of pedal tables for the part, keyed by
    ///                                 pedal. Empty tables are dropped. Defaults to an empty
    ///                                 dictionary.
    /// - Parameter markTable:          The mark table for the part. Defaults to an empty mark
    ///                                 table.
    /// - Parameter interpretationRules: How the part plays its ornaments, fermatas and caesuras,
    ///                                 over the work’s rules. Empty rules are stored as `nil`.
    ///                                 Defaults to `nil`.
    /// - Parameter extras:             Format-specific data about the part as a whole. Empty
    ///                                 extras are stored as `nil`. Defaults to `nil`.
    public init(name: String,
                noteTable: NoteTable<TimeType, PitchType>? = nil,
                dynamicMap: DynamicMap<TimeType>? = nil,
                instrumentTable: InstrumentTable<TimeType>? = nil,
                panMap: PanMap<TimeType>? = nil,
                pedals: [Pedal: PedalTable<TimeType>] = [:],
                markTable: PartMarkTable<TimeType>? = nil,
                interpretationRules: InterpretationRules? = nil,
                extras: Extras? = nil) {
        self.init(partID: PartID(),
                  name: name,
                  noteTable: noteTable,
                  dynamicMap: dynamicMap,
                  instrumentTable: instrumentTable,
                  panMap: panMap,
                  pedals: pedals,
                  markTable: markTable,
                  interpretationRules: interpretationRules,
                  extras: extras)
    }

    // MARK: Public Instance Properties

    /// The stable identity of this part, kept across saving and reopening.
    public let partID: PartID

    /// The dynamic map for this part.
    public var dynamicMap: DynamicMap<TimeType>

    /// Format-specific data about this part as a whole, or `nil` if there is none, such as the
    /// ``Extra/midiChannel`` its notes were imported from.
    ///
    /// It describes the whole part rather than any moment in it, so no transform moves or
    /// changes it. Empty extras are stored as `nil`.
    public var extras: Extras? {
        didSet { extras = Self._normalized(extras) }
    }

    /// The instrument table for this part.
    public var instrumentTable: InstrumentTable<TimeType>

    /// How this part plays its ornaments, fermatas and caesuras, field by field over the work’s
    /// ``Work/interpretationRules``, or `nil` to follow the work’s. Empty rules are stored as
    /// `nil`.
    ///
    /// Every rule is time-neutral, so no transform or conversion changes them.
    public var interpretationRules: InterpretationRules? {
        didSet { interpretationRules = Self._normalized(interpretationRules) }
    }

    /// The mark table for this part: its fermatas not on a note, and its caesuras.
    public var markTable: PartMarkTable<TimeType>

    /// The display name of this part, with whitespace normalized to a single line.
    public var name: String {
        didSet { name = name.normalizingWhitespace() }
    }

    /// The note table for this part.
    public var noteTable: NoteTable<TimeType, PitchType>

    /// The pan map for this part.
    public var panMap: PanMap<TimeType>

    /// The dictionary of pedal tables for this part, keyed by pedal.
    ///
    /// A pedal with no key has no entries, so it stays up throughout. Empty tables are removed on
    /// assignment, so they are never stored or encoded, and a part’s content doesn’t depend on
    /// whether an empty table was ever touched.
    public var pedals: [Pedal: PedalTable<TimeType>] {
        didSet { pedals = Self._normalized(pedals) }
    }

    // MARK: Internal Initializers

    //
    // Keeps an existing identity — for decoding, and for the work-level conversions that rebuild
    // a part with new content but must leave it the same part, so that whatever refers to it
    // (such as a `Realization`) still does.
    //
    internal init(partID: PartID,
                  name: String,
                  noteTable: NoteTable<TimeType, PitchType>? = nil,
                  dynamicMap: DynamicMap<TimeType>? = nil,
                  instrumentTable: InstrumentTable<TimeType>? = nil,
                  panMap: PanMap<TimeType>? = nil,
                  pedals: [Pedal: PedalTable<TimeType>] = [:],
                  markTable: PartMarkTable<TimeType>? = nil,
                  interpretationRules: InterpretationRules? = nil,
                  extras: Extras? = nil) {
        self.dynamicMap = dynamicMap ?? DynamicMap()
        self.extras = Self._normalized(extras)
        self.instrumentTable = instrumentTable ?? InstrumentTable()
        self.interpretationRules = Self._normalized(interpretationRules)
        self.markTable = markTable ?? PartMarkTable()
        //
        // `didSet` doesn't run during initialization, so normalize here too:
        //
        self.name = name.normalizingWhitespace()
        self.noteTable = noteTable ?? NoteTable()
        self.panMap = panMap ?? PanMap()
        self.partID = partID
        self.pedals = Self._normalized(pedals)
    }
}

// MARK: -

extension Part {

    // MARK: Public Instance Properties

    /// The number of notes in this part.
    public var noteCount: Int {
        noteTable.count
    }

    /// The pitch range spanned by the notes in this part, or `nil` if the part is empty.
    public var pitchRange: ClosedRange<PitchType>? {
        noteTable.pitchRange
    }

    /// The time range spanned by the notes in this part, or `nil` if the part is empty.
    public var timeRange: ClosedRange<TimeType>? {
        noteTable.timeRange
    }

    // MARK: Public Instance Methods

    /// Returns the identities of the notes in this part whose attack time falls within a range.
    ///
    /// - Parameter range:  The closed range of attack times to select.
    ///
    /// - Returns:  The identities of the matching notes, for use with any transform’s
    ///             `noteIDs:` parameter.
    public func attackingIn(_ range: ClosedRange<TimeType>) -> Set<NoteID> {
        noteTable.attackingIn(range)
    }

    /// Returns a copy of this part with the same content, ``interpretationRules`` and ``extras``
    /// but a distinct, freshly minted ``PartID``.
    ///
    /// The copy’s notes are the same notes under fresh identities, so the copy can join the
    /// original in one work, where no two notes may share a ``NoteID``.
    public func duplicated() -> Self {
        Self(name: name,
             noteTable: noteTable.renewingNoteIDs(),
             dynamicMap: dynamicMap,
             instrumentTable: instrumentTable,
             panMap: panMap,
             pedals: pedals,
             markTable: markTable,
             interpretationRules: interpretationRules,
             extras: extras)
    }

    /// Returns the identities of the notes in this part whose pitch — start, end, or anything a
    /// portamento glides through — falls within a range.
    ///
    /// - Parameter range:  The closed range of pitches to select.
    ///
    /// - Returns:  The identities of the matching notes, for use with any transform’s
    ///             `noteIDs:` parameter.
    public func pitchIn(_ range: ClosedRange<PitchType>) -> Set<NoteID> {
        noteTable.pitchIn(range)
    }

    /// Returns the identities of the notes in this part sounding at any point within a range —
    /// that is, whose attack-to-release span overlaps the range, not only notes that attack
    /// within it.
    ///
    /// - Parameter range:  The closed range of times to select.
    ///
    /// - Returns:  The identities of the matching notes, for use with any transform’s
    ///             `noteIDs:` parameter.
    public func soundingIn(_ range: ClosedRange<TimeType>) -> Set<NoteID> {
        noteTable.soundingIn(range)
    }

    // MARK: Internal Instance Methods

    //
    // This part with its arpeggio groups renumbered consecutively from `firstGroup`, in their
    // order, so its rolls don't join any in a work whose groups all lie below `firstGroup`.
    //
    internal func regroupingArpeggios(from firstGroup: ArpeggioGroup) -> Self {
        var groups: [ArpeggioGroup: ArpeggioGroup] = [:]

        for (offset, group) in noteTable.arpeggioGroups.sorted().enumerated() {
            groups[group] = ArpeggioGroup(uintValue: firstGroup.uintValue + UInt(offset)).require()
        }

        var part = self

        part.noteTable = noteTable.regroupingArpeggios(groups)

        return part
    }

    // MARK: Private Type Methods

    private static func _normalized(_ extras: Extras?) -> Extras? {
        extras?.isEmpty ?? true ? nil : extras
    }

    private static func _normalized(_ pedals: [Pedal: PedalTable<TimeType>]) -> [Pedal: PedalTable<TimeType>] {
        pedals.filter { !$0.value.isEmpty }
    }

    private static func _normalized(_ rules: InterpretationRules?) -> InterpretationRules? {
        rules?.isEmpty ?? true ? nil : rules
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

        let extras = try container.decodeIfPresent(Extras.self,
                                                   forKey: .extras)?.normalizingNames()

        let instrumentTable = try container.decode(InstrumentTable<TimeType>.self,
                                                   forKey: .instrumentTable)

        let interpretationRules = try container.decodeIfPresent(InterpretationRules.self,
                                                                forKey: .interpretationRules)

        let markTable = try container.decodeIfPresent(PartMarkTable<TimeType>.self,
                                                      forKey: .markTable)

        let name = try container.decode(String.self,
                                        forKey: .name)

        let noteTable = try container.decode(NoteTable<TimeType, PitchType>.self,
                                             forKey: .noteTable)

        let panMap = try container.decode(PanMap<TimeType>.self,
                                          forKey: .panMap)

        let partID = try container.decode(PartID.self,
                                          forKey: .partID)

        let pedals = try container.decode([Pedal: PedalTable<TimeType>].self,
                                          forKey: .pedals)

        self.init(partID: partID,
                  name: name,
                  noteTable: noteTable,
                  dynamicMap: dynamicMap,
                  instrumentTable: instrumentTable,
                  panMap: panMap,
                  pedals: pedals,
                  markTable: markTable,
                  interpretationRules: interpretationRules,
                  extras: extras)
    }

    // MARK: Public Instance Methods

    /// Encodes this part into the provided encoder. An empty mark table and `nil` interpretation
    /// rules are left out, like `nil` extras.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(partID,
                             forKey: .partID)

        try container.encode(name,
                             forKey: .name)

        try container.encode(noteTable,
                             forKey: .noteTable)

        try container.encode(dynamicMap,
                             forKey: .dynamicMap)

        try container.encode(instrumentTable,
                             forKey: .instrumentTable)

        try container.encode(panMap,
                             forKey: .panMap)

        try container.encode(pedals,
                             forKey: .pedals)

        if !markTable.isEmpty {
            try container.encode(markTable,
                                 forKey: .markTable)
        }

        try container.encodeIfPresent(interpretationRules,
                                      forKey: .interpretationRules)

        try container.encodeIfPresent(extras,
                                      forKey: .extras)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case dynamicMap
        case extras
        case instrumentTable
        case interpretationRules
        case markTable
        case name
        case noteTable
        case panMap
        case partID
        case pedals
    }
}

// MARK: - Sendable

extension Part: Sendable {
}
