// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

/// A unique identity for an entry in a time-keyed map, represented as a
/// validated string.
public struct EntryID {

    // MARK: Public Initializers

    /// Creates an entry identity from a string value already known to be
    /// valid.
    ///
    /// - Parameter stringValue:    The string identifying the entry.
    public init(uncheckedStringValue stringValue: String) {
        self.stringValue = stringValue
    }

    // MARK: Public Instance Properties

    /// The string value of this entry identity.
    public let stringValue: String
}

// MARK: - UniqueID

extension EntryID: UniqueID {

    // MARK: Public Type Properties

    public nonisolated(unsafe) static let validPattern = /E\$[0-9A-Za-z]{22}/

    public static let validPrefix = "E$"
}
