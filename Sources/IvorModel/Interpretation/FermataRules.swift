// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

/// How a work or part plays its fermatas by default: the composer’s general instructions, like a
/// score’s preface.
///
/// A fermata’s own execution overrides these, and anything left out here comes from the work’s
/// rules (for a part) or a built-in default for the fermata’s shape. Every field is
/// time-neutral, so the rules never need converting between beat and wall time.
public struct FermataRules {

    // MARK: Public Initializers

    /// Creates fermata rules with the provided fields.
    ///
    /// - Parameter holds:      How long each shape holds. A shape left out keeps its default.
    ///                         Defaults to none.
    /// - Parameter pauseAfter: The silence after each held span, in every part. Defaults to
    ///                         `nil`.
    public init(holds: [FermataShape: Hold] = [:],
                pauseAfter: PositiveDuration<WallDuration>? = nil) {
        self.holds = holds
        self.pauseAfter = pauseAfter
    }

    // MARK: Public Instance Properties

    /// How long each shape holds. A shape left out keeps its default.
    public let holds: [FermataShape: Hold]

    /// The silence after each held span, in every part, or `nil` for the default.
    public let pauseAfter: PositiveDuration<WallDuration>?
}

// MARK: -

extension FermataRules {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether no shape has a hold and there is no pause.
    public var isEmpty: Bool {
        holds.isEmpty && pauseAfter == nil
    }

    // MARK: Public Instance Methods

    /// Returns these rules with each hold and field that `other` sets replaced by its value. The
    /// holds combine shape by shape.
    ///
    /// - Parameter other:  The more specific rules, such as a part’s over its work’s.
    ///
    /// - Returns:  The combined rules.
    public func overridden(by other: Self?) -> Self {
        guard let other
        else { return self }

        return Self(holds: holds.merging(other.holds) { $1 },
                    pauseAfter: other.pauseAfter ?? pauseAfter)
    }
}

// MARK: - Codable

extension FermataRules: Codable {

    // MARK: Public Initializers

    /// Creates fermata rules by decoding them, with no holds if none are written.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try self.init(holds: container.decodeIfPresent([FermataShape: Hold].self, forKey: .holds) ?? [:],
                      pauseAfter: container.decodeIfPresent(PositiveDuration<WallDuration>.self, forKey: .pauseAfter))
    }

    // MARK: Public Instance Methods

    /// Encodes these rules, leaving out empty holds and a `nil` pause.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if !holds.isEmpty {
            try container.encode(holds, forKey: .holds)
        }

        try container.encodeIfPresent(pauseAfter, forKey: .pauseAfter)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case holds
        case pauseAfter
    }
}

// MARK: - Hashable

extension FermataRules: Hashable {
}

// MARK: - Sendable

extension FermataRules: Sendable {
}
