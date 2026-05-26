// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiTools

private import XestiNumbers

/// A time-indexed map of dynamic levels with a configurable default.
public struct DynamicMap<TimeType: TimeProtocol> {

    // MARK: Public Initializers

    /// Creates a new, empty dynamic map with the given default dynamic.
    ///
    /// - Parameter defaultDynamic: The dynamic level returned when the dynamic
    ///                             map is empty. Defaults to `.mp`.
    public init(defaultDynamic: Dynamic = .mp) {
        self.defaultDynamic = defaultDynamic
        self.entries = []
        self.hasExtras = false
    }

    // MARK: Public Instance Properties

    /// The dynamic level returned when this dynamic map contains no entries.
    public let defaultDynamic: Dynamic

    /// A Boolean value indicating whether any entry in this dynamic map
    /// carries extra data.
    public private(set) var hasExtras: Bool

    // MARK: Internal Instance Properties

    internal var entries: [Entry]
}

// MARK: -

extension DynamicMap {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether this dynamic map contains no entries.
    public var isEmpty: Bool {
        entries.isEmpty
    }

    // MARK: Public Instance Subscripts

    /// Returns the interpolated dynamic level in effect at the given time.
    ///
    /// - Parameter time:   The time at which to query the dynamic level.
    ///
    /// - Returns:  The linearly interpolated ``Dynamic`` value at `time`, or
    ///             ``defaultDynamic`` if this dynamic map is empty.
    public subscript(_ time: TimeType) -> Dynamic {
        guard !entries.isEmpty
        else { return defaultDynamic }

        guard let idx = entries.firstIndex(where: { time < $0.time })
        else { return entries[entries.endIndex - 1].dynamic }

        guard idx > 0
        else { return entries[0].dynamic }

        let startEntry = entries[idx - 1]
        let endEntry = entries[idx]

        let fraction = time.fraction(from: startEntry.time,
                                     through: endEntry.time)

        let rawStart = startEntry.dynamic.doubleValue
        let rawEnd = endEntry.dynamic.doubleValue
        let offset = (rawEnd - rawStart) * fraction

        return Dynamic(Number(rawStart + offset))
    }

    // MARK: Public Instance Methods

    /// Calls the given closure for each entry in this dynamic map, in order.
    ///
    /// - Parameter body:   A closure that receives the time, dynamic level, and
    ///                     optional extras for each entry.
    public func forEach(_ body: (TimeType, Dynamic, Extras?) -> Void) {
        entries.forEach {
            body($0.time,
                 $0.dynamic,
                 $0.extras)
        }
    }

    /// Inserts a dynamic entry into this dynamic map at the given time.
    ///
    /// - Parameter time:       The time at which the dynamic level takes effect.
    /// - Parameter dynamic:    The dynamic level to insert.
    /// - Parameter extras:     Optional extra data attached to the entry.
    ///                         Defaults to `nil`.
    public mutating func insert(time: TimeType,
                                dynamic: Dynamic,
                                extras: Extras? = nil) {
        entries.insert(Entry(time: time,
                             dynamic: dynamic,
                             extras: extras),
                       at: insertionIndex(for: time))

        if extras != nil {
            hasExtras = true
        }
    }

    /// Returns a copy of this dynamic map with a dynamic entry added at the
    /// given time.
    ///
    /// - Parameter time:       The time at which the dynamic level takes effect.
    /// - Parameter dynamic:    The dynamic level to insert.
    /// - Parameter extras:     Optional extra data attached to the entry.
    ///                         Defaults to `nil`.
    ///
    /// - Returns:  A new dynamic map with the entry inserted.
    public func inserting(time: TimeType,
                          dynamic: Dynamic,
                          extras: Extras? = nil) -> Self {
        var new = self

        new.insert(time: time,
                   dynamic: dynamic,
                   extras: extras)

        return new
    }

    /// Merges the entries from another dynamic map into this dynamic map.
    ///
    /// - Parameter other:  The dynamic map whose entries are merged into this
    ///                     dynamic map.
    public mutating func merge(with other: Self) {
        guard !other.entries.isEmpty
        else { return }

        guard !entries.isEmpty
        else { self = other; return }

        entries.append(contentsOf: other.entries)
        entries.sort()

        hasExtras = hasExtras || other.hasExtras
    }

    /// Returns a copy of this dynamic map merged with another dynamic map.
    ///
    /// - Parameter other:  The dynamic map to merge with.
    ///
    /// - Returns:  A new dynamic map containing the entries from the two
    ///             dynamic maps.
    public func merging(with other: Self) -> Self {
        var new = self

        new.merge(with: other)

        return new
    }

    /// Removes a matching dynamic entry from this dynamic map, if present.
    ///
    /// - Parameter time:       The time of the entry to remove.
    /// - Parameter dynamic:    The dynamic level of the entry to remove.
    /// - Parameter extras:     The optional extra data of the entry to remove.
    ///                         Defaults to `nil`.
    public mutating func remove(time: TimeType,
                                dynamic: Dynamic,
                                extras: Extras? = nil) {
        guard let index = firstIndex(time: time,
                                     dynamic: dynamic,
                                     extras: extras)
        else { return }

        entries.remove(at: index)

        if extras != nil {
            hasExtras = Self.hasExtras(in: entries)
        }
    }

    /// Returns a copy of this dynamic map with a matching entry removed.
    ///
    /// - Parameter time:       The time of the entry to remove.
    /// - Parameter dynamic:    The dynamic level of the entry to remove.
    /// - Parameter extras:     The optional extra data of the entry to remove.
    ///                         Defaults to `nil`.
    ///
    /// - Returns:  A new dynamic map with the matching entry removed.
    public func removing(time: TimeType,
                         dynamic: Dynamic,
                         extras: Extras? = nil) -> Self {
        var new = self

        new.remove(time: time,
                   dynamic: dynamic,
                   extras: extras)

        return new
    }
}

// MARK: - Codable

extension DynamicMap: Codable {
    /// Creates a dynamic map by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.defaultDynamic = try container.decode(Dynamic.self,
                                                   forKey: .defaultDynamic)

        self.entries = try container.decode([Entry].self,
                                            forKey: .entries)

        self.hasExtras = Self.hasExtras(in: entries)
    }

    /// Encodes this dynamic map into the provided encoder.
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

        try container.encode(defaultDynamic,
                             forKey: .defaultDynamic)
    }

    private enum CodingKeys: String, CodingKey {
        case defaultDynamic
        case entries
    }
}

// MARK: - Sendable

extension DynamicMap: Sendable {
}
