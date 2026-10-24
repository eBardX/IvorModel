// © 2026 John Gary Pusey (see LICENSE.md)

/// The patch ``Assignment`` each ``Instrument`` has, so that what an instrument designates can be
/// realized differently in different places — `Vanilla` as a grand piano in one part, say, and
/// as a pipe organ in another.
///
/// A ``Realization`` holds a patch table for each part that needs one, and one more of
/// work-wide defaults, for the instruments a part’s own table doesn’t assign. An instrument
/// assigned in neither is left for the app to realize as it sees fit.
public struct PatchTable {

    // MARK: Public Initializers

    /// Creates a patch table from the given assignment for each instrument.
    ///
    /// - Parameter assignments:    The patch assignment for each instrument. Defaults to none.
    public init(_ assignments: [Instrument: Assignment] = [:]) {
        self.assignments = assignments
    }

    // MARK: Public Instance Properties

    /// The patch assignment for each instrument.
    public private(set) var assignments: [Instrument: Assignment]
}

// MARK: -

extension PatchTable {

    // MARK: Public Instance Properties

    /// The number of instruments with a patch assignment.
    public var count: Int {
        assignments.count
    }

    /// The instruments with a patch assignment, in order.
    public var instruments: [Instrument] {
        assignments.keys.sorted()
    }

    /// A Boolean value indicating whether no instrument has a patch assignment.
    public var isEmpty: Bool {
        assignments.isEmpty
    }

    // MARK: Public Subscripts

    /// The patch assignment for the given instrument, or `nil` if it has none. Setting it to
    /// `nil` removes the instrument’s assignment.
    ///
    /// - Parameter instrument: The instrument.
    public subscript(instrument: Instrument) -> Assignment? {
        get { assignments[instrument] }
        set { assignments[instrument] = newValue }
    }
}

// MARK: - Codable

extension PatchTable: Codable {

    // MARK: Public Initializers

    /// Creates a patch table by decoding from the provided decoder.
    ///
    /// A patch table is encoded as an array of instrument and patch assignment pairs.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted, or if an
    ///             instrument is assigned more than once.
    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var assignments: [Instrument: Assignment] = [:]

        while !container.isAtEnd {
            var pair = try container.nestedUnkeyedContainer()

            let instrument = try pair.decode(Instrument.self)
            let assignment = try pair.decode(Assignment.self)

            guard assignments.updateValue(assignment,
                                          forKey: instrument) == nil
            else { throw DecodingError.dataCorruptedError(in: container,
                                                          debugDescription: "Duplicate instrument: \(instrument)") }
        }

        self.init(assignments)
    }

    // MARK: Public Instance Methods

    /// Encodes this patch table into the provided encoder, in order of instrument.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        for (instrument, assignment) in assignments.sorted(by: { $0.key < $1.key }) {
            var pair = container.nestedUnkeyedContainer()

            try pair.encode(instrument)
            try pair.encode(assignment)
        }
    }
}

// MARK: - Hashable

extension PatchTable: Hashable {
}

// MARK: - Sendable

extension PatchTable: Sendable {
}
