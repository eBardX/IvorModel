public import IvorTiming
public import XestiTools

private import XestiNumbers

public struct TempoMap {

    // MARK: Public Initializers

    public init(defaultTempo: Tempo = .default) {
        self.defaultTempo = defaultTempo
        self.entries = []
        self.hasExtras = false
    }

    // MARK: Public Instance Properties

    public let defaultTempo: Tempo

    public private(set) var hasExtras: Bool

    // MARK: Internal Instance Properties

    internal var entries: [Entry]
}

// MARK: -

extension TempoMap {

    // MARK: Public Instance Properties

    public var isEmpty: Bool {
        entries.isEmpty
    }

    // MARK: Public Instance Subscripts

    public subscript(_ beatTime: BeatTime) -> Tempo {
        guard !entries.isEmpty
        else { return defaultTempo }

        guard let idx = entries.firstIndex(where: { beatTime < $0.beatTime })
        else { return entries[entries.endIndex - 1].tempo }

        guard idx > 0
        else { return entries[0].tempo }

        let startEntry = entries[idx - 1]
        let endEntry = entries[idx]

        let fraction = beatTime.fraction(from: startEntry.beatTime,
                                         through: endEntry.beatTime)

        let rawStart = Int(startEntry.tempo.uintValue)
        let rawEnd = Int(endEntry.tempo.uintValue)
        let offset = Int((Double(rawEnd - rawStart) * fraction * fraction).rounded())

        return Tempo(UInt(max(1, rawStart + offset)))
    }

    // MARK: Public Instance Methods

    public func forEach(_ body: (BeatTime, Tempo, Extras?) -> Void) {
        entries.forEach {
            body($0.beatTime,
                 $0.tempo,
                 $0.extras)
        }
    }

    public mutating func insert(beatTime: BeatTime,
                                tempo: Tempo,
                                extras: Extras? = nil) {
        entries.insert(Entry(beatTime: beatTime,
                             tempo: tempo,
                             extras: extras),
                       at: indexForInserting(beatTime: beatTime))

        if extras != nil {
            hasExtras = true
        }

        rebuildDerivedFields()
    }

    public func inserting(beatTime: BeatTime,
                          tempo: Tempo,
                          extras: Extras? = nil) -> Self {
        var new = self

        new.insert(beatTime: beatTime,
                   tempo: tempo,
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

        rebuildDerivedFields()
    }

    public func merging(with other: Self) -> Self {
        var new = self

        new.merge(with: other)

        return new
    }

    public mutating func remove(beatTime: BeatTime,
                                tempo: Tempo,
                                extras: Extras? = nil) {
        guard let index = indexMatching(beatTime: beatTime,
                                        tempo: tempo,
                                        extras: extras)
        else { return }

        entries.remove(at: index)

        if extras != nil {
            hasExtras = Self.determineHasExtras(entries)
        }

        rebuildDerivedFields()
    }

    public func removing(beatTime: BeatTime,
                         tempo: Tempo,
                         extras: Extras? = nil) -> Self {
        var new = self

        new.remove(beatTime: beatTime,
                   tempo: tempo,
                   extras: extras)

        return new
    }

    public func beatTime(at wallTime: WallTime) -> BeatTime {
        guard !entries.isEmpty
        else { return BeatTime(wallTime.numberValue * (defaultTempo.numberValue / Tempo.default.numberValue)) }

        if wallTime < entries[0].wallTime {
            return BeatTime(wallTime.numberValue * entries[0].tempo.numberValue / Tempo.default.numberValue)
        }

        let entry = entries[bestIndex(for: wallTime)]
        let tempoDelta = entry.tempoDelta
        let wallFraction = (wallTime - entry.wallTime).numberValue / entry.wallDuration.numberValue

        if tempoDelta < 0 {
            let scale = sqrt(-tempoDelta / entry.tempo.numberValue)
            let fraction = tanh(wallFraction * atanh(scale)) / scale

            return entry.beatTime + entry.beatDuration * fraction
        }

        if tempoDelta > 0 {
            let scale = sqrt(tempoDelta / entry.tempo.numberValue)
            let fraction = tan(wallFraction * atan(scale)) / scale

            return entry.beatTime + entry.beatDuration * fraction
        }

        return entry.beatTime + entry.beatDuration * wallFraction
    }

    public func wallTime(at beatTime: BeatTime) -> WallTime {
        guard !entries.isEmpty
        else { return WallTime(beatTime.numberValue * (Tempo.default.numberValue / defaultTempo.numberValue)) }

        if beatTime < entries[0].beatTime {
            return WallTime(beatTime.numberValue * Tempo.default.numberValue / entries[0].tempo.numberValue)
        }

        let entry = entries[bestIndex(for: beatTime)]
        let tempoDelta = entry.tempoDelta
        let beatFraction = (beatTime - entry.beatTime).numberValue / entry.beatDuration.numberValue

        if tempoDelta < 0 {
            let scale = sqrt(-tempoDelta / entry.tempo.numberValue)
            let fraction = atanh(beatFraction * scale) / atanh(scale)

            return entry.wallTime + entry.wallDuration * fraction
        }

        if tempoDelta > 0 {
            let scale = sqrt(tempoDelta / entry.tempo.numberValue)
            let fraction = atan(beatFraction * scale) / atan(scale)

            return entry.wallTime + entry.wallDuration * fraction
        }

        return entry.wallTime + entry.wallDuration * beatFraction
    }
}

// MARK: - Codable

extension TempoMap: Codable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.defaultTempo = try container.decode(Tempo.self,
                                                 forKey: .defaultTempo)

        self.entries = try container.decode([Entry].self,
                                            forKey: .entries)

        self.hasExtras = Self.determineHasExtras(entries)

        rebuildDerivedFields()
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(entries,
                             forKey: .entries)

        try container.encode(defaultTempo,
                             forKey: .defaultTempo)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case defaultTempo
        case entries
    }
}

// MARK: - Sendable

extension TempoMap: Sendable {
}
