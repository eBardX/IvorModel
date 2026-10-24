// © 2026 John Gary Pusey (see LICENSE.md)

private import XestiTools

/// One way of realizing a ``Work`` when it plays: a ``PatchTable`` of work-wide defaults, plus a
/// patch table for each part that needs one.
///
/// A realization is not part of the music. A work holds one or more — say “General MIDI” for
/// sharing and “My studio” for one’s own hardware — and which one plays is up to the app.
/// Choosing a realization voices every part of the work at once.
///
/// Each part’s table is keyed by its ``PartID``. A part’s assignment for an instrument wins over
/// the work-wide default; an instrument assigned in neither is left for the app to realize as it
/// sees fit.
public struct Realization {

    // MARK: Public Initializers

    /// Creates a realization with a fresh identity.
    ///
    /// - Parameter name:       The display name of the realization. Its whitespace is
    ///                         normalized to a single line. Defaults to an empty string.
    /// - Parameter defaults:   The work-wide patch table, for instruments a part’s own table
    ///                         doesn’t assign. Defaults to an empty patch table.
    /// - Parameter partTables: The patch table for each part. Empty tables are dropped.
    ///                         Defaults to none.
    public init(name: String = "",
                defaults: PatchTable = PatchTable(),
                partTables: [PartID: PatchTable] = [:]) {
        self.init(realizationID: RealizationID(),
                  name: name,
                  defaults: defaults,
                  partTables: partTables)
    }

    // MARK: Internal Initializers

    internal init(realizationID: RealizationID,
                  name: String,
                  defaults: PatchTable,
                  partTables: [PartID: PatchTable]) {
        self.defaults = defaults
        //
        // `didSet` doesn't run during initialization, so normalize here too:
        //
        self.name = name.normalizingWhitespace()
        self.partTables = partTables.filter { !$0.value.isEmpty }
        self.realizationID = realizationID
    }

    // MARK: Public Instance Properties

    /// The unique ID of this realization.
    public let realizationID: RealizationID

    /// The work-wide patch table, for instruments a part’s own table doesn’t assign.
    public var defaults: PatchTable

    /// The display name of this realization, with whitespace normalized to a single line.
    public var name: String {
        didSet { name = name.normalizingWhitespace() }
    }

    /// The patch table for each part that has a non-empty one.
    ///
    /// To change a part’s table, use ``subscript(_:)``.
    public private(set) var partTables: [PartID: PatchTable]
}

// MARK: -

extension Realization {

    // MARK: Public Subscripts

    /// The patch table for the part with the given ID, or an empty patch table if it has none.
    /// Setting it to an empty patch table removes the part’s table.
    ///
    /// - Parameter partID: The ID of the part.
    public subscript(_ partID: PartID) -> PatchTable {
        get { partTables[partID] ?? PatchTable() }
        set { partTables[partID] = newValue.isEmpty ? nil : newValue }
    }

    // MARK: Public Instance Methods

    /// Returns the patch assignment for an instrument in a part: the part’s own, else the
    /// work-wide default.
    ///
    /// - Parameter instrument: The instrument.
    /// - Parameter partID:     The ID of the part the instrument plays in.
    ///
    /// - Returns:  The patch assignment, or `nil` if neither the part’s table nor the defaults
    ///             assign `instrument`.
    public func assignment(for instrument: Instrument,
                           in partID: PartID) -> PatchTable.Assignment? {
        partTables[partID]?[instrument] ?? defaults[instrument]
    }

    /// Returns a copy of this realization with the same patch tables but a distinct, freshly
    /// minted ``RealizationID``.
    ///
    /// - Parameter name:   The display name of the copy. Defaults to this realization’s name.
    public func duplicated(name: String? = nil) -> Self {
        Self(name: name ?? self.name,
             defaults: defaults,
             partTables: partTables)
    }

    // MARK: Internal Instance Methods

    internal mutating func copyPartTable(from sourceID: PartID,
                                         to destinationID: PartID) {
        partTables[destinationID] = partTables[sourceID]
    }

    internal mutating func removePartTables(notIn partIDs: Set<PartID>) {
        partTables = partTables.filter { partIDs.contains($0.key) }
    }
}

// MARK: - Codable

extension Realization: Codable {

    // MARK: Public Initializers

    /// Creates a realization by decoding from the provided decoder.
    ///
    /// The part tables are encoded as an array of part ID and patch table pairs.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted, or if a part has
    ///             more than one table.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let defaults = try container.decode(PatchTable.self,
                                            forKey: .defaults)

        let name = try container.decode(String.self,
                                        forKey: .name)

        var pairs = try container.nestedUnkeyedContainer(forKey: .partTables)
        var partTables: [PartID: PatchTable] = [:]

        while !pairs.isAtEnd {
            var pair = try pairs.nestedUnkeyedContainer()

            let partID = try pair.decode(PartID.self)
            let table = try pair.decode(PatchTable.self)

            guard partTables.updateValue(table,
                                         forKey: partID) == nil
            else { throw DecodingError.dataCorruptedError(in: pairs,
                                                          debugDescription: "Duplicate part: \(partID.stringValue)") }
        }

        let realizationID = try container.decode(RealizationID.self,
                                                 forKey: .realizationID)

        self.init(realizationID: realizationID,
                  name: name,
                  defaults: defaults,
                  partTables: partTables)
    }

    // MARK: Public Instance Methods

    /// Encodes this realization into the provided encoder, with its part tables in order of part
    /// ID.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(realizationID,
                             forKey: .realizationID)

        try container.encode(name,
                             forKey: .name)

        try container.encode(defaults,
                             forKey: .defaults)

        var pairs = container.nestedUnkeyedContainer(forKey: .partTables)

        for (partID, table) in partTables.sorted(by: { $0.key < $1.key }) {
            var pair = pairs.nestedUnkeyedContainer()

            try pair.encode(partID)
            try pair.encode(table)
        }
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case defaults
        case name
        case partTables
        case realizationID
    }
}

// MARK: - Hashable

extension Realization: Hashable {
}

// MARK: - Sendable

extension Realization: Sendable {
}
