// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiTools

/// What one performer (or one unison section) plays: one or more strands of notes, and the
/// things the performer controls as a whole — a dynamic map, an instrument table, a pan map,
/// pedal tables, a mark table, and interpretation rules.
///
/// A part always has at least one ``Strand``, in score order. Most parts have one; a pianist’s
/// part might have one per hand, an organist’s one per manual and one for the pedals. A strand
/// may carry its own instrument table or dynamic map, which replaces the part’s for its notes;
/// ``instrumentTable(for:)`` and ``dynamicMap(for:)`` give the one a strand uses.
public struct Part<TimeType: TimeProtocol, PitchType: PitchProtocol> {

    // MARK: Public Type Aliases

    /// The duration type associated with the time type.
    public typealias DurationType = TimeType.DurationType

    /// The interval type associated with the pitch type.
    public typealias IntervalType = PitchType.IntervalType

    // MARK: Public Initializers

    /// Creates a part with one strand, with the given name and optional note, map, instrument,
    /// pedal and mark data, interpretation rules, and extras.
    ///
    /// - Parameter name:               The display name of the part. Its whitespace is
    ///                                 normalized to a single line.
    /// - Parameter noteTable:          The notes of the part’s one, unnamed strand. Defaults to
    ///                                 none.
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
                  strands: [Strand(noteTable: noteTable ?? NoteTable())],
                  dynamicMap: dynamicMap,
                  instrumentTable: instrumentTable,
                  panMap: panMap,
                  pedals: pedals,
                  markTable: markTable,
                  interpretationRules: interpretationRules,
                  extras: extras)
    }

    /// Creates a part with the given strands, name and optional map, instrument, pedal and mark
    /// data, interpretation rules, and extras.
    ///
    /// - Parameter name:               The display name of the part. Its whitespace is
    ///                                 normalized to a single line.
    /// - Parameter strands:            The part’s strands, in score order. There must be at
    ///                                 least one, and no two may share a ``StrandID``.
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
    ///
    /// - Precondition: `strands` is non-empty, and its strands’ IDs are distinct.
    public init(name: String,
                strands: [Strand<TimeType, PitchType>],
                dynamicMap: DynamicMap<TimeType>? = nil,
                instrumentTable: InstrumentTable<TimeType>? = nil,
                panMap: PanMap<TimeType>? = nil,
                pedals: [Pedal: PedalTable<TimeType>] = [:],
                markTable: PartMarkTable<TimeType>? = nil,
                interpretationRules: InterpretationRules? = nil,
                extras: Extras? = nil) {
        precondition(Self.strandError(in: strands) == nil,
                     "A part needs at least one strand, with distinct strand IDs.")

        self.init(partID: PartID(),
                  name: name,
                  strands: strands,
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

    /// The dynamic map for this part, used by every strand that has no dynamic map of its own.
    public var dynamicMap: DynamicMap<TimeType>

    /// Format-specific data about this part as a whole, or `nil` if there is none, such as the
    /// ``Extra/midiChannel`` its notes were imported from.
    ///
    /// It describes the whole part rather than any moment in it, so no transform moves or
    /// changes it. Empty extras are stored as `nil`.
    public var extras: Extras? {
        didSet { extras = Self._normalized(extras) }
    }

    /// The instrument table for this part, used by every strand that has no instrument table of
    /// its own.
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

    /// The part’s strands, in score order: never empty, and no two sharing a ``StrandID``.
    ///
    /// To change one, use ``modifyStrand(_:_:)``.
    public internal(set) var strands: [Strand<TimeType, PitchType>]

    // MARK: Internal Initializers

    //
    // Keeps an existing identity — for decoding, and for the work-level conversions that rebuild
    // a part with new content but must leave it the same part, so that whatever refers to it
    // (such as a `Realization`) still does.
    //
    internal init(partID: PartID,
                  name: String,
                  strands: [Strand<TimeType, PitchType>],
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
        self.panMap = panMap ?? PanMap()
        self.partID = partID
        self.pedals = Self._normalized(pedals)
        self.strands = strands
    }
}

// MARK: -

extension Part {

    // MARK: Public Instance Properties

    /// All of this part’s notes, from every strand, in one note table, in time order.
    ///
    /// A view for reading the part as a whole, such as for display or export. It isn’t stored:
    /// to change notes, change a strand’s.
    public var mergedNoteTable: NoteTable<TimeType, PitchType> {
        guard strands.count > 1
        else { return strands[0].noteTable }

        var merged = NoteTable<TimeType, PitchType>()

        for strand in strands {
            merged.merge(with: strand.noteTable)
        }

        return merged
    }

    /// The number of notes in this part, across all of its strands.
    public var noteCount: Int {
        strands.reduce(0) { $0 + $1.noteTable.count }
    }

    /// The pitch range spanned by the notes in this part, across all of its strands, or `nil` if
    /// the part has no notes.
    public var pitchRange: ClosedRange<PitchType>? {
        strands.compactMap(\.noteTable.pitchRange).reduce(nil) { acc, range in
            acc.map { NoteTable<TimeType, PitchType>.mergePitchRanges($0, range) } ?? range
        }
    }

    /// The IDs of this part’s strands, in score order.
    public var strandIDs: [StrandID] {
        strands.map(\.strandID)
    }

    /// The time range spanned by the notes in this part, across all of its strands, or `nil` if
    /// the part has no notes.
    public var timeRange: ClosedRange<TimeType>? {
        strands.compactMap(\.noteTable.timeRange).reduce(nil) { acc, range in
            acc.map { NoteTable<TimeType, PitchType>.mergeTimeRanges($0, range) } ?? range
        }
    }

    /// An arpeggio group no note in this part belongs to: one past the largest in use, or the
    /// first group if there are none.
    public var unusedArpeggioGroup: ArpeggioGroup {
        let largest = arpeggioGroups.max()?.uintValue ?? 0

        return ArpeggioGroup(uintValue: largest + 1).require()
    }

    // MARK: Public Instance Methods

    /// Returns the identities of the notes in this part, in any strand, whose attack time falls
    /// within a range.
    ///
    /// - Parameter range:  The closed range of attack times to select.
    ///
    /// - Returns:  The identities of the matching notes, for use with any transform’s
    ///             `noteIDs:` parameter.
    public func attackingIn(_ range: ClosedRange<TimeType>) -> Set<NoteID> {
        strands.reduce(into: []) { $0.formUnion($1.noteTable.attackingIn(range)) }
    }

    /// Returns a copy of this part with the same content, ``interpretationRules`` and ``extras``
    /// but a distinct, freshly minted ``PartID``.
    ///
    /// The copy’s strands are the same strands under fresh ``StrandID``s, and its notes the same
    /// notes under fresh identities, so the copy can join the original in one work, where no two
    /// strands may share a ``StrandID`` and no two notes a ``NoteID``.
    public func duplicated() -> Self {
        Self(partID: PartID(),
             name: name,
             strands: strands.map { $0.duplicated() },
             dynamicMap: dynamicMap,
             instrumentTable: instrumentTable,
             panMap: panMap,
             pedals: pedals,
             markTable: markTable,
             interpretationRules: interpretationRules,
             extras: extras)
    }

    /// Returns the dynamic map a strand of this part uses: its own if it has one, otherwise the
    /// part’s.
    ///
    /// - Parameter strand: A strand of this part.
    ///
    /// - Returns:  The dynamic map the strand’s notes follow.
    public func dynamicMap(for strand: Strand<TimeType, PitchType>) -> DynamicMap<TimeType> {
        strand.dynamicMap ?? dynamicMap
    }

    /// Returns the zero-based position of the strand with the given ID, in score order.
    ///
    /// - Parameter strandID:   The ID of the strand.
    ///
    /// - Returns:  The strand’s position, or `nil` if no strand of this part has `strandID`.
    public func index(ofStrandID strandID: StrandID) -> Int? {
        strands.firstIndex { $0.strandID == strandID }
    }

    /// Returns the instrument table a strand of this part uses: its own if it has one, otherwise
    /// the part’s.
    ///
    /// - Parameter strand: A strand of this part.
    ///
    /// - Returns:  The instrument table the strand’s notes follow.
    public func instrumentTable(for strand: Strand<TimeType, PitchType>) -> InstrumentTable<TimeType> {
        strand.instrumentTable ?? instrumentTable
    }

    /// Edits one strand of this part in place.
    ///
    /// The strand keeps its ``StrandID``, whatever `body` does.
    ///
    /// - Parameter strandID:   The ID of the strand to edit.
    /// - Parameter body:       A closure that edits the strand in place, and whose result is
    ///                         returned.
    ///
    /// - Returns:  The result of `body`, or `nil` (without calling `body`) if no strand of this
    ///             part has `strandID`.
    @discardableResult
    public mutating func modifyStrand<R>(_ strandID: StrandID,
                                         _ body: (inout Strand<TimeType, PitchType>) -> R) -> R? {
        guard let index = index(ofStrandID: strandID)
        else { return nil }

        return body(&strands[index])
    }

    /// Returns the identities of the notes in this part, in any strand, whose pitch — start, end,
    /// or anything a portamento glides through — falls within a range.
    ///
    /// - Parameter range:  The closed range of pitches to select.
    ///
    /// - Returns:  The identities of the matching notes, for use with any transform’s
    ///             `noteIDs:` parameter.
    public func pitchIn(_ range: ClosedRange<PitchType>) -> Set<NoteID> {
        strands.reduce(into: []) { $0.formUnion($1.noteTable.pitchIn(range)) }
    }

    /// Returns the identities of the notes in this part, in any strand, sounding at any point
    /// within a range — that is, whose attack-to-release span overlaps the range, not only notes
    /// that attack within it.
    ///
    /// - Parameter range:  The closed range of times to select.
    ///
    /// - Returns:  The identities of the matching notes, for use with any transform’s
    ///             `noteIDs:` parameter.
    public func soundingIn(_ range: ClosedRange<TimeType>) -> Set<NoteID> {
        strands.reduce(into: []) { $0.formUnion($1.noteTable.soundingIn(range)) }
    }

    /// Returns the strand with the given ID.
    ///
    /// - Parameter strandID:   The ID of the strand.
    ///
    /// - Returns:  The strand, or `nil` if no strand of this part has `strandID`.
    public func strand(_ strandID: StrandID) -> Strand<TimeType, PitchType>? {
        strands.first { $0.strandID == strandID }
    }

    // MARK: Internal Type Methods

    //
    // Why `strands` can't be a part's, or `nil` if it can: a part needs at least one strand, and
    // no two of its strands may share an ID.
    //
    internal static func strandError(in strands: [Strand<TimeType, PitchType>]) -> String? {
        guard !strands.isEmpty
        else { return "A part needs at least one strand" }

        var seen: Set<StrandID> = []

        if let duplicate = strands.first(where: { !seen.insert($0.strandID).inserted }) {
            return "Duplicate strand ID: \(duplicate.strandID.stringValue)"
        }

        return nil
    }

    // MARK: Internal Instance Properties

    //
    // The arpeggio groups any of this part's notes belong to.
    //
    internal var arpeggioGroups: Set<ArpeggioGroup> {
        strands.reduce(into: []) { $0.formUnion($1.noteTable.arpeggioGroups) }
    }

    //
    // The ID of every note of every strand, in score order.
    //
    internal var noteIDs: [NoteID] {
        strands.flatMap { $0.noteTable.notes.map(\.noteID) }
    }

    // MARK: Internal Instance Methods

    //
    // This part, keeping its identity and everything else, with each strand's note table (and own
    // instrument table and dynamic map) mapped by the closures: for the conversions that change
    // a part's time or pitch type, or rebuild its notes.
    //
    internal func mappingStrands<T, P, E: Swift.Error>(noteTable: (NoteTable<TimeType, PitchType>) throws(E) -> NoteTable<T, P>,
                                                       instrumentTable: (InstrumentTable<TimeType>) -> InstrumentTable<T>,
                                                       dynamicMap: (DynamicMap<TimeType>) -> DynamicMap<T>) throws(E) -> [Strand<T, P>] {
        var result: [Strand<T, P>] = []

        for strand in strands {
            try result.append(strand.replacingNoteTable(with: noteTable(strand.noteTable),
                                                        instrumentTable: strand.instrumentTable.map(instrumentTable),
                                                        dynamicMap: strand.dynamicMap.map(dynamicMap)))
        }

        return result
    }

    //
    // This part with its arpeggio groups renumbered consecutively from `firstGroup`, in their
    // order, so its rolls don't join any in a work whose groups all lie below `firstGroup`.
    //
    internal func regroupingArpeggios(from firstGroup: ArpeggioGroup) -> Self {
        var groups: [ArpeggioGroup: ArpeggioGroup] = [:]

        for (offset, group) in arpeggioGroups.sorted().enumerated() {
            groups[group] = ArpeggioGroup(uintValue: firstGroup.uintValue + UInt(offset)).require()
        }

        var part = self

        for index in part.strands.indices {
            part.strands[index].noteTable = strands[index].noteTable.regroupingArpeggios(groups)
        }

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
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted, including a part
    ///             with no strands or with two strands sharing an ID.
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

        let panMap = try container.decode(PanMap<TimeType>.self,
                                          forKey: .panMap)

        let partID = try container.decode(PartID.self,
                                          forKey: .partID)

        let pedals = try container.decode([Pedal: PedalTable<TimeType>].self,
                                          forKey: .pedals)

        let strands = try container.decode([Strand<TimeType, PitchType>].self,
                                           forKey: .strands)

        if let reason = Self.strandError(in: strands) {
            throw DecodingError.dataCorruptedError(forKey: .strands,
                                                   in: container,
                                                   debugDescription: reason)
        }

        self.init(partID: partID,
                  name: name,
                  strands: strands,
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

        try container.encode(strands,
                             forKey: .strands)

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
        case panMap
        case partID
        case pedals
        case strands
    }
}

// MARK: - Sendable

extension Part: Sendable {
}
