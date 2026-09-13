// © 2025–2026 John Gary Pusey (see LICENSE.md)

/// A set of a part’s parameter maps that a time-based transform should also carry along.
public struct MapTargets: OptionSet {

    // MARK: Public Initializers

    /// Creates a set of parameter map targets from the given raw value.
    ///
    /// - Parameter rawValue:   The raw value of the set.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    // MARK: Public Instance Properties

    /// The raw value of this set.
    public let rawValue: Int
}

// MARK: -

extension MapTargets {

    // MARK: Public Type Properties

    /// Every parameter map, including the work’s own tempo map.
    public static let all: Self = [.dynamic, .instrument, .pan, .tempo]

    /// The dynamic map.
    public static let dynamic = Self(rawValue: 1 << 0)

    /// The instrument map.
    public static let instrument = Self(rawValue: 1 << 1)

    /// The pan map.
    public static let pan = Self(rawValue: 1 << 2)

    /// The work’s own tempo map. Only meaningful to a whole-work transform — a `Part` has no
    /// tempo map of its own, so this target is ignored wherever `MapTargets` selects among a
    /// single part’s maps.
    public static let tempo = Self(rawValue: 1 << 3)
}

// MARK: - Sendable

extension MapTargets: Sendable {
}
