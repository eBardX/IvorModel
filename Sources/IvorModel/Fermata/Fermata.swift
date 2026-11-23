// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

/// A fermata: its sign, and optionally how this occurrence is played.
///
/// The ``shape`` is the sign, what the score shows. The ``execution``, if any, holds the
/// composer’s instructions for this fermata. A fermata on a note spans that note; one on a rest
/// or a bar line is a part mark that carries its own span.
public struct Fermata<TimeType: TimeProtocol> {

    // MARK: Public Initializers

    /// Creates a fermata with the provided shape and execution.
    ///
    /// - Parameter shape:      The shape of the sign. Defaults to ``FermataShape/normal``.
    /// - Parameter execution:  How this fermata is played, or `nil` to follow the rules.
    ///                         Defaults to `nil`.
    public init(shape: FermataShape = .normal,
                execution: FermataExecution<TimeType>? = nil) {
        self.execution = execution
        self.shape = shape
    }

    // MARK: Public Instance Properties

    /// How this fermata is played, or `nil` to follow the rules. Part of the execution, not
    /// the sign.
    public let execution: FermataExecution<TimeType>?

    /// The shape of the sign. Part of the sign.
    public let shape: FermataShape
}

// MARK: -

extension Fermata {

    // MARK: Public Instance Methods

    /// Returns this fermata with its execution’s lengths in the work’s own time scaled by a
    /// factor, or `nil` if a scaled length is zero or can’t be computed.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled fermata, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        guard let execution
        else { return self }

        return execution.scaled(by: factor).map { Self(shape: shape, execution: $0) }
    }
}

// MARK: - Codable

extension Fermata: Codable {
}

// MARK: - Hashable

extension Fermata: Hashable {
}

// MARK: - Sendable

extension Fermata: Sendable {
}
