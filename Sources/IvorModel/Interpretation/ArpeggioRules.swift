// © 2026 John Gary Pusey (see LICENSE.md)

/// How a work or part plays its arpeggios by default: the composer’s general instructions, like
/// a score’s preface.
///
/// Every field is optional. An arpeggio’s own sign and execution override these, and a field
/// left out here comes from the work’s rules (for a part) or a built-in default. Every field is
/// time-neutral, so the rules never need converting between beat and wall time.
public struct ArpeggioRules {

    // MARK: Public Initializers

    /// Creates arpeggio rules with the provided fields, each `nil` by default.
    ///
    /// - Parameter direction:  Which way arpeggios whose signs give no direction roll.
    /// - Parameter anchor:     Which tone of a roll falls on the beat.
    /// - Parameter spread:     How far apart a roll’s tones start.
    public init(direction: ArpeggioDirection? = nil,
                anchor: ArpeggioAnchor? = nil,
                spread: Spread? = nil) {
        self.anchor = anchor
        self.direction = direction
        self.spread = spread
    }

    // MARK: Public Instance Properties

    /// Which tone of a roll falls on the beat, or `nil` for the default.
    public let anchor: ArpeggioAnchor?

    /// Which way arpeggios whose signs give no direction roll, or `nil` for the default (up).
    public let direction: ArpeggioDirection?

    /// How far apart a roll’s tones start, or `nil` for the default.
    public let spread: Spread?
}

// MARK: -

extension ArpeggioRules {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether every field is `nil`.
    public var isEmpty: Bool {
        anchor == nil && direction == nil && spread == nil
    }

    // MARK: Public Instance Methods

    /// Returns these rules with each field that `other` sets replaced by its value.
    ///
    /// - Parameter other:  The more specific rules, such as a part’s over its work’s.
    ///
    /// - Returns:  The combined rules.
    public func overridden(by other: Self?) -> Self {
        guard let other
        else { return self }

        return Self(direction: other.direction ?? direction,
                    anchor: other.anchor ?? anchor,
                    spread: other.spread ?? spread)
    }
}

// MARK: - Codable

extension ArpeggioRules: Codable {
}

// MARK: - Hashable

extension ArpeggioRules: Hashable {
}

// MARK: - Sendable

extension ArpeggioRules: Sendable {
}
