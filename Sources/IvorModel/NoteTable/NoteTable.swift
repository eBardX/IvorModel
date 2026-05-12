public import IvorTiming
public import IvorTuning

public struct NoteTable<TimeType: TimeProtocol, PitchType: PitchProtocol> {

    // MARK: Public Nested Types

    public typealias DurationType = TimeType.DurationType
    public typealias IntervalType = PitchType.IntervalType

    // MARK: Public Initializers

    public init() {
        self.init(notes: [])
    }

    // MARK: Public Instance Properties

    public internal(set) var hasExtras: Bool
    public internal(set) var hasPortamento: Bool
    public internal(set) var isMonophonic: Bool
    public internal(set) var pitchRange: ClosedRange<PitchType>
    public internal(set) var timeRange: ClosedRange<TimeType>

    // MARK: Internal Initializers

    internal init(notes: [Note]) {
        self.hasExtras = Self.determineHasExtras(notes)
        self.hasPortamento = Self.determineHasPortamento(notes)
        self.isMonophonic = Self.determineIsMonophonic(notes)
        self.notes = notes
        self.pitchRange = Self.determinePitchRange(notes)
        self.timeRange = Self.determineTimeRange(notes)
    }

    // MARK: Internal Instance Properties

    internal var notes: [Note]
}

// MARK: - Codable

extension NoteTable: Codable {

    // MARK: Public Initializers

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try self.init(notes: container.decode([Note].self,
                                              forKey: .notes))

        notes.sort()
    }

    // MARK: Public Instance Methods

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
