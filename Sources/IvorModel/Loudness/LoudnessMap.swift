public import IvorTiming
public import XestiTools

private import XestiNumbers

public struct LoudnessMap<TimeType: TimeProtocol> {

    // MARK: Public Initializers

    public init(defaultLoudness: Loudness = .mp) {
        self.defaultLoudness = defaultLoudness
        self.entries = []
        self.hasExtras = false
    }

    // MARK: Public Instance Properties

    public let defaultLoudness: Loudness

    public private(set) var hasExtras: Bool

    // MARK: Internal Instance Properties

    internal var entries: [Entry]
}

// MARK: -

extension LoudnessMap {

    // MARK: Public Instance Properties

    public var isEmpty: Bool {
        entries.isEmpty
    }

    // MARK: Public Instance Subscripts

    public subscript(_ time: TimeType) -> Loudness {
        guard !entries.isEmpty
        else { return defaultLoudness }

        guard let idx = entries.firstIndex(where: { time < $0.time })
        else { return entries[entries.endIndex - 1].loudness }

        guard idx > 0
        else { return entries[0].loudness }

        let startEntry = entries[idx - 1]
        let endEntry = entries[idx]

        let fraction = time.fraction(from: startEntry.time,
                                     through: endEntry.time)

        let rawStart = startEntry.loudness.doubleValue
        let rawEnd = endEntry.loudness.doubleValue
        let offset = (rawEnd - rawStart) * fraction

        return Loudness(Number(rawStart + offset))
    }

    // MARK: Public Instance Methods

    public func forEach(_ body: (TimeType, Loudness, Extras?) -> Void) {
        entries.forEach {
            body($0.time,
                 $0.loudness,
                 $0.extras)
        }
    }

    public mutating func insert(time: TimeType,
                                loudness: Loudness,
                                extras: Extras? = nil) {
        entries.insert(Entry(time: time,
                             loudness: loudness,
                             extras: extras),
                       at: indexForInserting(time: time))

        if extras != nil {
            hasExtras = true
        }
    }

    public func inserting(time: TimeType,
                          loudness: Loudness,
                          extras: Extras? = nil) -> Self {
        var new = self

        new.insert(time: time,
                   loudness: loudness,
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
                                loudness: Loudness,
                                extras: Extras? = nil) {
        guard let index = indexMatching(time: time,
                                        loudness: loudness,
                                        extras: extras)
        else { return }

        entries.remove(at: index)

        if extras != nil {
            hasExtras = Self.determineHasExtras(entries)
        }
    }

    public func removing(time: TimeType,
                         loudness: Loudness,
                         extras: Extras? = nil) -> Self {
        var new = self

        new.remove(time: time,
                   loudness: loudness,
                   extras: extras)

        return new
    }
}

// MARK: - Codable

extension LoudnessMap: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.defaultLoudness = try container.decode(Loudness.self,
                                                    forKey: .defaultLoudness)

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

        try container.encode(defaultLoudness,
                             forKey: .defaultLoudness)
    }

    private enum CodingKeys: String, CodingKey {
        case defaultLoudness
        case entries
    }
}

// MARK: - Sendable

extension LoudnessMap: Sendable {
}
