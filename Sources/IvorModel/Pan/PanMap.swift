// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiTools

private import XestiNumbers

/// A time-indexed map of stereo pan positions with a configurable default.
public struct PanMap<TimeType: TimeProtocol> {

    // MARK: Public Initializers

    /// Creates a new, empty pan map with the given default pan position.
    ///
    /// - Parameter defaultPan: The pan position returned when the pan map is empty.
    ///                         Defaults to `.center`.
    public init(defaultPan: Pan = .center) {
        self.init(defaultPan: defaultPan,
                  entries: [])
    }

    // MARK: Public Instance Properties

    /// The pan position returned when this pan map contains no entries.
    public let defaultPan: Pan

    /// A Boolean value indicating whether any entry in this pan map carries
    /// extra data.
    public private(set) var hasExtras: Bool

    // MARK: Internal Initializers

    internal init(defaultPan: Pan,
                  entries: [Entry]) {
        self.defaultPan = defaultPan
        self.entries = entries
        self.hasExtras = Self.hasExtras(in: entries)
    }

    // MARK: Internal Instance Properties

    internal var entries: [Entry]
}

// MARK: -

extension PanMap {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether this pan map contains no entries.
    public var isEmpty: Bool {
        entries.isEmpty
    }

    // MARK: Public Instance Subscripts

    /// Returns the interpolated pan position in effect at the given time.
    ///
    /// - Parameter time:   The time at which to query the pan position.
    ///
    /// - Returns:  The linearly interpolated ``Pan`` value at `time`, or
    ///             ``defaultPan`` if this pan map is empty.
    public subscript(_ time: TimeType) -> Pan {
        guard !entries.isEmpty
        else { return defaultPan }

        guard let idx = entries.firstIndex(where: { time < $0.time })
        else { return entries[entries.endIndex - 1].pan }

        guard idx > 0
        else { return entries[0].pan }

        let startEntry = entries[idx - 1]
        let endEntry = entries[idx]

        let fraction = time.fraction(from: startEntry.time,
                                     through: endEntry.time)

        let rawStart = startEntry.pan.doubleValue
        let rawEnd = endEntry.pan.doubleValue
        let offset = (rawEnd - rawStart) * fraction

        return Pan(Number(rawStart + offset))
    }

    // MARK: Public Instance Methods

    /// Calls the given closure for each entry in this pan map, in order.
    ///
    /// - Parameter body:   A closure that receives the time, pan position, and
    ///                     optional extras for each entry.
    public func forEach(_ body: (TimeType, Pan, Extras?) -> Void) {
        entries.forEach {
            body($0.time,
                 $0.pan,
                 $0.extras)
        }
    }

    /// Inserts a pan entry into this pan map at the given time.
    ///
    /// - Parameter time:   The time at which the pan position takes effect.
    /// - Parameter pan:    The pan position to insert.
    /// - Parameter extras: Optional extra data attached to the entry. Defaults
    ///                     to `nil`.
    public mutating func insert(time: TimeType,
                                pan: Pan,
                                extras: Extras? = nil) {
        entries.insert(Entry(time: time,
                             pan: pan,
                             extras: extras),
                       at: insertionIndex(for: time))

        if extras != nil {
            hasExtras = true
        }
    }

    /// Returns a copy of this pan map with a pan entry added at the given time.
    ///
    /// - Parameter time:   The time at which the pan position takes effect.
    /// - Parameter pan:    The pan position to insert.
    /// - Parameter extras: Optional extra data attached to the entry. Defaults
    ///                     to `nil`.
    ///
    /// - Returns:  A new pan map with the entry inserted.
    public func inserting(time: TimeType,
                          pan: Pan,
                          extras: Extras? = nil) -> Self {
        var new = self

        new.insert(time: time,
                   pan: pan,
                   extras: extras)

        return new
    }

    /// Merges the entries from another pan map into this pan map.
    ///
    /// - Parameter other:  The pan map whose entries are merged into this pan
    ///                     map.
    public mutating func merge(with other: Self) {
        guard !other.entries.isEmpty
        else { return }

        guard !entries.isEmpty
        else { self = other; return }

        entries.append(contentsOf: other.entries)
        entries.sort()

        hasExtras = hasExtras || other.hasExtras
    }

    /// Returns a copy of this pan map merged with another pan map.
    ///
    /// - Parameter other:  The pan map to merge with.
    ///
    /// - Returns:  A new pan map containing the entries from the two pan maps.
    public func merging(with other: Self) -> Self {
        var new = self

        new.merge(with: other)

        return new
    }

    /// Removes a matching pan entry from this pan map, if present.
    ///
    /// - Parameter time:   The time of the entry to remove.
    /// - Parameter pan:    The pan position of the entry to remove.
    /// - Parameter extras: The optional extra data of the entry to remove.
    ///                     Defaults to `nil`.
    public mutating func remove(time: TimeType,
                                pan: Pan,
                                extras: Extras? = nil) {
        guard let index = firstIndex(time: time,
                                     pan: pan,
                                     extras: extras)
        else { return }

        entries.remove(at: index)

        if extras != nil {
            hasExtras = Self.hasExtras(in: entries)
        }
    }

    /// Returns a copy of this pan map with a matching entry removed.
    ///
    /// - Parameter time:   The time of the entry to remove.
    /// - Parameter pan:    The pan position of the entry to remove.
    /// - Parameter extras: The optional extra data of the entry to remove.
    ///                     Defaults to `nil`.
    ///
    /// - Returns:  A new pan map with the matching entry removed.
    public func removing(time: TimeType,
                         pan: Pan,
                         extras: Extras? = nil) -> Self {
        var new = self

        new.remove(time: time,
                   pan: pan,
                   extras: extras)

        return new
    }
}

// MARK: - Codable

extension PanMap: Codable {
    /// Creates a pan map by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.defaultPan = try container.decode(Pan.self,
                                               forKey: .defaultPan)

        self.entries = try container.decode([Entry].self,
                                            forKey: .entries)

        self.hasExtras = Self.hasExtras(in: entries)
    }

    /// Encodes this pan map into the provided encoder.
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

        try container.encode(defaultPan,
                             forKey: .defaultPan)
    }

    private enum CodingKeys: String, CodingKey {
        case defaultPan
        case entries
    }
}

// MARK: - Sendable

extension PanMap: Sendable {
}
