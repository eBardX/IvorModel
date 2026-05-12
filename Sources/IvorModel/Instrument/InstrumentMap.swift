public import IvorTiming
public import XestiTools

public struct InstrumentMap<TimeType: TimeProtocol> {

    // MARK: Public Initializers

    public init(defaultInstrument: Instrument = .vanilla) {
        self.defaultInstrument = defaultInstrument
        self.entries = []
        self.hasExtras = false
    }

    // MARK: Public Instance Properties

    public let defaultInstrument: Instrument

    public private(set) var hasExtras: Bool

    // MARK: Internal Instance Properties

    internal var entries: [Entry]
}

// MARK: -

extension InstrumentMap {

    // MARK: Public Instance Properties

    public var isEmpty: Bool {
        entries.isEmpty
    }

    // MARK: Public Instance Subscripts

    public subscript(_ time: TimeType) -> Instrument {
        guard !entries.isEmpty
        else { return defaultInstrument }

        guard let idx = entries.firstIndex(where: { time < $0.time })
        else { return entries[entries.endIndex - 1].instrument }

        guard idx > 0
        else { return entries[0].instrument }

        return entries[idx - 1].instrument
    }

    // MARK: Public Instance Methods

    public func forEach(_ body: (TimeType, Instrument, Extras?) -> Void) {
        entries.forEach {
            body($0.time,
                 $0.instrument,
                 $0.extras)
        }
    }

    public mutating func insert(time: TimeType,
                                instrument: Instrument,
                                extras: Extras? = nil) {
        entries.insert(Entry(time: time,
                             instrument: instrument,
                             extras: extras),
                       at: indexForInserting(time: time))

        if extras != nil {
            hasExtras = true
        }
    }

    public func inserting(time: TimeType,
                          instrument: Instrument,
                          extras: Extras? = nil) -> Self {
        var new = self

        new.insert(time: time,
                   instrument: instrument,
                   extras: extras)

        return new
    }

    public mutating func merge(with other: Self) {
        guard !other.entries.isEmpty
        else { return }

        guard !entries.isEmpty
        else { self = other; return }

        entries.append(contentsOf: other.entries)
        entries.sort()

        hasExtras = hasExtras || other.hasExtras
    }

    public func merging(with other: Self) -> Self {
        var new = self

        new.merge(with: other)

        return new
    }

    public mutating func remove(time: TimeType,
                                instrument: Instrument,
                                extras: Extras? = nil) {
        guard let index = indexMatching(time: time,
                                        instrument: instrument,
                                        extras: extras)
        else { return }

        entries.remove(at: index)

        if extras != nil {
            hasExtras = Self.determineHasExtras(entries)
        }
    }

    public func removing(time: TimeType,
                         instrument: Instrument,
                         extras: Extras? = nil) -> Self {
        var new = self

        new.remove(time: time,
                   instrument: instrument,
                   extras: extras)

        return new
    }
}

// MARK: - Codable

extension InstrumentMap: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.defaultInstrument = try container.decode(Instrument.self,
                                                      forKey: .defaultInstrument)

        self.entries = try container.decode([Entry].self,
                                            forKey: .entries)

        self.hasExtras = Self.determineHasExtras(entries)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(entries,
                             forKey: .entries)

        try container.encode(defaultInstrument,
                             forKey: .defaultInstrument)
    }

    private enum CodingKeys: String, CodingKey {
        case defaultInstrument
        case entries
    }
}

// MARK: - Sendable

extension InstrumentMap: Sendable {
}
