// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

/// A note table keyed by time and pitch.
public struct NoteTable<TimeType: TimeProtocol, PitchType: PitchProtocol> {

    // MARK: Public Nested Types

    /// The duration type associated with the time type.
    public typealias DurationType = TimeType.DurationType

    /// The interval type associated with the pitch type.
    public typealias IntervalType = PitchType.IntervalType

    // MARK: Public Initializers

    /// Creates a new, empty note table.
    public init() {
        self.init(notes: [])
    }

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether any note in the note table carries extra data.
    public internal(set) var hasExtras: Bool

    /// A Boolean value indicating whether any note in the note table has portamento (differing start and end pitches).
    public internal(set) var hasPortamento: Bool

    /// A Boolean value indicating whether the note table is monophonic.
    public internal(set) var isMonophonic: Bool

    /// The closed range of pitches spanned by the notes in the note table, or `nil` if the table is empty.
    public internal(set) var pitchRange: ClosedRange<PitchType>?

    /// The closed range of times spanned by the notes in the note table, or `nil` if the table is empty.
    public internal(set) var timeRange: ClosedRange<TimeType>?

    // MARK: Internal Initializers

    internal init(notes: [Note]) {
        self.hasExtras = Self.hasExtras(in: notes)
        self.hasPortamento = Self.hasPortamento(in: notes)
        self.isMonophonic = Self.isMonophonic(in: notes)
        self.notes = notes
        self.pitchRange = Self.pitchRange(in: notes)
        self.timeRange = Self.timeRange(in: notes)
    }

    // MARK: Internal Instance Properties

    internal var notes: [Note]
}

// MARK: - Codable

extension NoteTable: Codable {

    // MARK: Public Initializers

    /// Creates a note table by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try self.init(notes: container.decode([Note].self,
                                              forKey: .notes))

        notes.sort()
    }

    // MARK: Public Instance Methods

    /// Encodes this note table into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(notes,
                             forKey: .notes)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case notes
    }
}

// MARK: - Sendable

extension NoteTable: Sendable {
}
