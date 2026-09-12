// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

/// A unique ID for a ``Work``, represented as a validated string.
public struct WorkID {

    // MARK: Public Initializers

    /// Creates a work ID from a string value already known to be valid.
    ///
    /// - Parameter stringValue:    The string identifying the work.
    public init(uncheckedStringValue stringValue: String) {
        self.stringValue = stringValue
    }

    // MARK: Public Instance Properties

    /// The string value of this work ID.
    public let stringValue: String
}

// MARK: - UniqueID

extension WorkID: UniqueID {

    // MARK: Public Type Properties

    public nonisolated(unsafe) static let validPattern = /W\$[0-9A-Za-z]{22}/

    public static let validPrefix = "W$"
}
