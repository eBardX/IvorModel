// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiTools

/// A time-indexed map of instrument designations with a configurable default.
public struct InstrumentMap<TimeType: TimeProtocol> {

    // MARK: Public Initializers

    /// Creates a new, empty instrument map with the given default instrument.
    ///
    /// - Parameter defaultInstrument:  The instrument returned when the
    ///                                 instrument map is empty. Defaults to
    ///                                 `.vanilla`.
    public init(defaultInstrument: Instrument = .vanilla) {
        self.defaultInstrument = defaultInstrument
        self.entries = []
        self.hasExtras = false
    }

    // MARK: Public Instance Properties

    /// The instrument returned when this instrument map contains no entries.
    public let defaultInstrument: Instrument

    /// A Boolean value indicating whether any entry in this instrument map
    /// carries extra data.
    public private(set) var hasExtras: Bool

    // MARK: Internal Instance Properties

    internal var entries: [Entry]
}

// MARK: -

extension InstrumentMap {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether this instrument map contains no
    /// entries.
    public var isEmpty: Bool {
        entries.isEmpty
    }

    // MARK: Public Instance Subscripts

    /// Returns the instrument in effect at the given time.
    ///
    /// - Parameter time:   The time at which to query the instrument.
    ///
    /// - Returns:  The ``Instrument`` value in effect at `time`, or
    ///             ``defaultInstrument`` if this instrument map is empty.
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

    /// Calls the given closure for each entry in this instrument map, in order.
    ///
    /// - Parameter body:   A closure that receives the time, instrument, and
    ///                     optional extras for each entry.
    public func forEach(_ body: (TimeType, Instrument, Extras?) -> Void) {
        entries.forEach {
            body($0.time,
                 $0.instrument,
                 $0.extras)
        }
    }

    /// Inserts an instrument entry into this instrument map at the given time.
    ///
    /// - Parameter time:       The time at which the instrument takes effect.
    /// - Parameter instrument: The instrument to insert.
    /// - Parameter extras:     Optional extra data attached to the entry.
    ///                         Defaults to `nil`.
    public mutating func insert(time: TimeType,
                                instrument: Instrument,
                                extras: Extras? = nil) {
        entries.insert(Entry(time: time,
                             instrument: instrument,
                             extras: extras),
                       at: insertionIndex(for: time))

        if extras != nil {
            hasExtras = true
        }
    }

    /// Returns a copy of this instrument map with an instrument entry added at
    /// the given time.
    ///
    /// - Parameter time:        The time at which the instrument takes effect.
    /// - Parameter instrument:  The instrument to insert.
    /// - Parameter extras:      Optional extra data attached to the entry.
    ///                         Defaults to `nil`.
    ///
    /// - Returns:  A new instrument map with the entry inserted.
    public func inserting(time: TimeType,
                          instrument: Instrument,
                          extras: Extras? = nil) -> Self {
        var new = self

        new.insert(time: time,
                   instrument: instrument,
                   extras: extras)

        return new
    }

    /// Merges the entries from another instrument map into this instrument map.
    ///
    /// - Parameter other:  The instrument map whose entries are merged into
    ///                     this instrument map.
    public mutating func merge(with other: Self) {
        guard !other.entries.isEmpty
        else { return }

        guard !entries.isEmpty
        else { self = other; return }

        entries.append(contentsOf: other.entries)
        entries.sort()

        hasExtras = hasExtras || other.hasExtras
    }

    /// Returns a copy of this instrument map merged with another instrument
    /// map.
    ///
    /// - Parameter other:  The instrument map to merge with.
    ///
    /// - Returns:  A new instrument map containing the entries from the two
    ///             instrument maps.
    public func merging(with other: Self) -> Self {
        var new = self

        new.merge(with: other)

        return new
    }

    /// Removes a matching instrument entry from this instrument map, if
    /// present.
    ///
    /// - Parameter time:       The time of the entry to remove.
    /// - Parameter instrument: The instrument designation of the entry to remove.
    /// - Parameter extras:     The optional extra data of the entry to remove.
    ///                         Defaults to `nil`.
    public mutating func remove(time: TimeType,
                                instrument: Instrument,
                                extras: Extras? = nil) {
        guard let index = firstIndex(time: time,
                                     instrument: instrument,
                                     extras: extras)
        else { return }

        entries.remove(at: index)

        if extras != nil {
            hasExtras = Self.hasExtras(in: entries)
        }
    }

    /// Returns a copy of this instrument map with a matching entry removed.
    ///
    /// - Parameter time:       The time of the entry to remove.
    /// - Parameter instrument: The instrument designation of the entry to remove.
    /// - Parameter extras:     The optional extra data of the entry to remove.
    ///                         Defaults to `nil`.
    ///
    /// - Returns:  A new instrument map with the matching entry removed.
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
    /// Creates an instrument map by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.defaultInstrument = try container.decode(Instrument.self,
                                                      forKey: .defaultInstrument)

        self.entries = try container.decode([Entry].self,
                                            forKey: .entries)

        self.hasExtras = Self.hasExtras(in: entries)
    }

    /// Encodes this instrument map into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
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
