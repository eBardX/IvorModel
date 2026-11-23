// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

/// How one fermata is played: the composer’s instructions for this occurrence.
///
/// Every field is optional. One left out comes from the work’s or part’s interpretation rules,
/// or else from a built-in default for the fermata’s shape. A fermata has no span of its own
/// here: a note’s fermata spans its note, and a fermata mark carries its span in the mark.
public struct FermataExecution<TimeType: TimeProtocol> {

    // MARK: Public Initializers

    /// Creates a fermata execution with the provided fields, each `nil` by default.
    ///
    /// - Parameter hold:       How much longer the held span lasts.
    /// - Parameter pauseAfter: The silence after the held span, in every part.
    /// - Parameter isPlayed:   `false` if the fermata is notation only and isn’t played.
    public init(hold: Hold? = nil,
                pauseAfter: Pause<TimeType>? = nil,
                isPlayed: Bool? = nil) {
        self.hold = hold
        self.isPlayed = isPlayed
        self.pauseAfter = pauseAfter
    }

    // MARK: Public Instance Properties

    /// How much longer the held span lasts, or `nil` to take it from the rules.
    public let hold: Hold?

    /// A Boolean value indicating whether the fermata is played: `false` if it is notation
    /// only, or `nil` to take it from the rules.
    public let isPlayed: Bool?

    /// The silence after the held span, in every part, or `nil` to take it from the rules.
    public let pauseAfter: Pause<TimeType>?
}

// MARK: -

extension FermataExecution {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether every field is `nil`.
    public var isEmpty: Bool {
        hold == nil && isPlayed == nil && pauseAfter == nil
    }

    // MARK: Public Instance Methods

    /// Returns this execution with its lengths in the work’s own time scaled by a factor, or
    /// `nil` if a scaled length is zero or can’t be computed.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled execution, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        var hold = hold
        var pauseAfter = pauseAfter

        if let value = hold {
            guard let scaled = value.scaled(by: factor)
            else { return nil }

            hold = scaled
        }

        if let value = pauseAfter {
            guard let scaled = value.scaled(by: factor)
            else { return nil }

            pauseAfter = scaled
        }

        return Self(hold: hold,
                    pauseAfter: pauseAfter,
                    isPlayed: isPlayed)
    }
}

// MARK: - Codable

extension FermataExecution: Codable {
}

// MARK: - Hashable

extension FermataExecution: Hashable {
}

// MARK: - Sendable

extension FermataExecution: Sendable {
}
