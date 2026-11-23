// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

/// How one caesura is played: the composer’s instructions for this occurrence.
///
/// A caesura is a moment, so it has no span. Its pause, if left out, comes from the rules or a
/// built-in default.
public struct CaesuraExecution<TimeType: TimeProtocol> {

    // MARK: Public Initializers

    /// Creates a caesura execution with the provided pause.
    ///
    /// - Parameter pause:  The pause at the caesura, or `nil` to take it from the rules.
    ///                     Defaults to `nil`.
    public init(pause: Pause<TimeType>? = nil) {
        self.pause = pause
    }

    // MARK: Public Instance Properties

    /// The pause at the caesura, in every part, or `nil` to take it from the rules.
    public let pause: Pause<TimeType>?
}

// MARK: -

extension CaesuraExecution {

    // MARK: Public Instance Methods

    /// Returns this execution with its pause’s length in the work’s own time scaled by a
    /// factor, or `nil` if the scaled length is zero or can’t be computed.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled execution, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        guard let pause
        else { return self }

        return pause.scaled(by: factor).map { Self(pause: $0) }
    }
}

// MARK: - Codable

extension CaesuraExecution: Codable {
}

// MARK: - Hashable

extension CaesuraExecution: Hashable {
}

// MARK: - Sendable

extension CaesuraExecution: Sendable {
}
