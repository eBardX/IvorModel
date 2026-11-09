// © 2025–2026 John Gary Pusey (see LICENSE.md)

/// A set of the time-keyed collections that a time-based transform should carry along with the
/// notes: a part’s parameter maps and instrument table, and the work’s own tempo map.
public struct TransformTargets {

    // MARK: Public Initializers

    /// Creates a set of transform targets from the given raw value.
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

extension TransformTargets {

    // MARK: Public Type Properties

    /// Every target: the parameter maps, the instrument table, and the work’s own tempo map.
    public static let all: Self = [.dynamic, .instrument, .pan, .tempo]

    /// The dynamic map.
    public static let dynamic = Self(rawValue: 1 << 0)

    /// The instrument table.
    public static let instrument = Self(rawValue: 1 << 1)

    /// The pan map.
    public static let pan = Self(rawValue: 1 << 2)

    /// The work’s own tempo map. Only meaningful to a whole-work transform — a `Part` has no
    /// tempo map of its own, so this target is ignored wherever `TransformTargets` selects among a
    /// single part’s maps and table.
    public static let tempo = Self(rawValue: 1 << 3)
}

// MARK: - OptionSet

extension TransformTargets: OptionSet {
}

// MARK: - Sendable

extension TransformTargets: Sendable {
}
