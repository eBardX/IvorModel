// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

/// How a work or part plays its grace figures by default: the composer’s general instructions,
/// like a score’s preface.
///
/// Every field is optional. A figure’s own execution overrides these, and a field left out here
/// comes from the work’s rules (for a part) or a built-in default. Every field is time-neutral,
/// so the rules never need converting between beat and wall time.
public struct GraceRules {

    // MARK: Public Initializers

    /// Creates grace rules with the provided fields, each `nil` by default.
    ///
    /// - Parameter slashedPlacement:   Where slashed figures (acciaccaturas) fall.
    /// - Parameter unslashedPlacement: Where unslashed figures (appoggiaturas) fall.
    /// - Parameter maximumShare:       The most of a note a figure may take its time from.
    /// - Parameter perNote:            The time each grace event takes when it has no written
    ///                                 length.
    public init(slashedPlacement: GracePlacement? = nil,
                unslashedPlacement: GracePlacement? = nil,
                maximumShare: Proportion? = nil,
                perNote: PositiveDuration<WallDuration>? = nil) {
        self.maximumShare = maximumShare
        self.perNote = perNote
        self.slashedPlacement = slashedPlacement
        self.unslashedPlacement = unslashedPlacement
    }

    // MARK: Public Instance Properties

    /// The most of a note a figure may take its time from, or `nil` for the default.
    public let maximumShare: Proportion?

    /// The time each grace event takes when it has no written length, or `nil` for the default.
    public let perNote: PositiveDuration<WallDuration>?

    /// Where slashed figures (acciaccaturas) fall, or `nil` for the default.
    public let slashedPlacement: GracePlacement?

    /// Where unslashed figures (appoggiaturas) fall, or `nil` for the default.
    public let unslashedPlacement: GracePlacement?
}

// MARK: -

extension GraceRules {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether every field is `nil`.
    public var isEmpty: Bool {
        maximumShare == nil && perNote == nil && slashedPlacement == nil && unslashedPlacement == nil
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

        return Self(slashedPlacement: other.slashedPlacement ?? slashedPlacement,
                    unslashedPlacement: other.unslashedPlacement ?? unslashedPlacement,
                    maximumShare: other.maximumShare ?? maximumShare,
                    perNote: other.perNote ?? perNote)
    }
}

// MARK: - Codable

extension GraceRules: Codable {
}

// MARK: - Hashable

extension GraceRules: Hashable {
}

// MARK: - Sendable

extension GraceRules: Sendable {
}
