public import IvorTiming
public import XestiTools

private import XestiNumbers

public struct PositionMap<TimeType: TimeProtocol> {

    // MARK: Public Initializers

    public init(defaultPosition: Position = .center) {
        self.defaultPosition = defaultPosition
        self.entries = []
        self.hasExtras = false
    }

    // MARK: Public Instance Properties

    public let defaultPosition: Position

    public private(set) var hasExtras: Bool

    // MARK: Internal Instance Properties

    internal var entries: [Entry]
}

// MARK: -

extension PositionMap {

    // MARK: Public Instance Properties

    public var isEmpty: Bool {
        entries.isEmpty
    }

    // MARK: Public Instance Subscripts

    public subscript(_ time: TimeType) -> Position {
        guard !entries.isEmpty
        else { return defaultPosition }

        guard let idx = entries.firstIndex(where: { time < $0.time })
        else { return entries[entries.endIndex - 1].position }

        guard idx > 0
        else { return entries[0].position }

        let startEntry = entries[idx - 1]
        let endEntry = entries[idx]

        let fraction = time.fraction(from: startEntry.time,
                                     through: endEntry.time)

        let rawStart = startEntry.position.doubleValue
        let rawEnd = endEntry.position.doubleValue
        let offset = (rawEnd - rawStart) * fraction

        return Position(Number(rawStart + offset))
    }

    // MARK: Public Instance Methods

    public func forEach(_ body: (TimeType, Position, Extras?) -> Void) {
        entries.forEach {
            body($0.time,
                 $0.position,
                 $0.extras)
        }
    }

    public mutating func insert(time: TimeType,
                                position: Position,
                                extras: Extras? = nil) {
        entries.insert(Entry(time: time,
                             position: position,
                             extras: extras),
                       at: indexForInserting(time: time))

        if extras != nil {
            hasExtras = true
        }
    }

    public func inserting(time: TimeType,
                          position: Position,
                          extras: Extras? = nil) -> Self {
        var new = self

        new.insert(time: time,
                   position: position,
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
                                position: Position,
                                extras: Extras? = nil) {
        guard let index = indexMatching(time: time,
                                        position: position,
                                        extras: extras)
        else { return }

        entries.remove(at: index)

        if extras != nil {
            hasExtras = Self.determineHasExtras(entries)
        }
    }

    public func removing(time: TimeType,
                         position: Position,
                         extras: Extras? = nil) -> Self {
        var new = self

        new.remove(time: time,
                   position: position,
                   extras: extras)

        return new
    }
}

// MARK: - Codable

extension PositionMap: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.defaultPosition = try container.decode(Position.self,
                                                    forKey: .defaultPosition)

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

        try container.encode(defaultPosition,
                             forKey: .defaultPosition)
    }

    private enum CodingKeys: String, CodingKey {
        case defaultPosition
        case entries
    }
}

// MARK: - Sendable

extension PositionMap: Sendable {
}
