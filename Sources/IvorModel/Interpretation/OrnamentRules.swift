// © 2026 John Gary Pusey (see LICENSE.md)

/// How a work or part plays one kind of ornament by default — its trills, its mordents or its
/// tremolos: the composer’s general instructions, like a score’s preface.
///
/// Every field is optional. An ornament’s own execution overrides these, and a field left out
/// here comes from the work’s rules (for a part) or a built-in default. Every field is
/// time-neutral: a rate is in notes per second, never a written note value, so the rules never
/// need converting between beat and wall time.
public struct OrnamentRules {

    // MARK: Public Initializers

    /// Creates ornament rules with the provided fields, each `nil` by default.
    ///
    /// - Parameter startNote:      Whether ornaments start on their main note or their partner.
    /// - Parameter partnerRule:    How far a step partner with no written pitch lies from the
    ///                             main note.
    /// - Parameter rate:           How fast ornaments alternate. For tremolos, it applies to
    ///                             unmeasured ones only: a measured tremolo follows its strokes.
    /// - Parameter extent:         How much of the note ornaments fill, overriding their signs’
    ///                             defaults.
    public init(startNote: OrnamentStart? = nil,
                partnerRule: PartnerRule? = nil,
                rate: NotesPerSecond? = nil,
                extent: OrnamentExtent? = nil) {
        self.extent = extent
        self.partnerRule = partnerRule
        self.rate = rate
        self.startNote = startNote
    }

    // MARK: Public Instance Properties

    /// How much of the note ornaments fill, or `nil` to take it from their signs.
    public let extent: OrnamentExtent?

    /// How far a step partner with no written pitch lies from the main note, or `nil` for the
    /// default.
    public let partnerRule: PartnerRule?

    /// How fast ornaments alternate, or `nil` for the default.
    public let rate: NotesPerSecond?

    /// Whether ornaments start on their main note or their partner, or `nil` for the default.
    public let startNote: OrnamentStart?
}

// MARK: -

extension OrnamentRules {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether every field is `nil`.
    public var isEmpty: Bool {
        extent == nil && partnerRule == nil && rate == nil && startNote == nil
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

        return Self(startNote: other.startNote ?? startNote,
                    partnerRule: other.partnerRule ?? partnerRule,
                    rate: other.rate ?? rate,
                    extent: other.extent ?? extent)
    }
}

// MARK: - Codable

extension OrnamentRules: Codable {
}

// MARK: - Hashable

extension OrnamentRules: Hashable {
}

// MARK: - Sendable

extension OrnamentRules: Sendable {
}
