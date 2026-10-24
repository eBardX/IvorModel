// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

/// A unique ID for a ``Realization``, represented as a validated string.
///
/// Persisted with the realization. A realization’s ID is unique within its ``Work``;
/// a duplicated work’s realizations keep theirs, so the same ID may appear in more
/// than one work.
public struct RealizationID {

    // MARK: Public Initializers

    /// Creates a realization ID from a string value already known to be valid.
    ///
    /// - Parameter stringValue:    The string identifying the realization.
    public init(uncheckedStringValue stringValue: String) {
        self.stringValue = stringValue
    }

    // MARK: Public Instance Properties

    /// The string value of this realization ID.
    public let stringValue: String
}

// MARK: - UniqueID

extension RealizationID: UniqueID {

    // MARK: Public Type Properties

    public nonisolated(unsafe) static let validPattern = /R\$[0-9A-Za-z]{22}/

    public static let validPrefix = "R$"
}
