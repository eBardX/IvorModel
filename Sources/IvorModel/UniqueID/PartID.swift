// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

/// A unique ID for a ``Part``, represented as a validated string.
///
/// Persisted with the part, so a part keeps its identity across a save and reopen,
/// and anything that refers to it by ID — such as a ``Realization`` — still does.
/// A part’s ID is unique within its ``Work``; a duplicated work’s parts keep theirs,
/// so the same ID may appear in more than one work.
public struct PartID {

    // MARK: Public Initializers

    /// Creates a part ID from a string value already known to be valid.
    ///
    /// - Parameter stringValue:    The string identifying the part.
    public init(uncheckedStringValue stringValue: String) {
        self.stringValue = stringValue
    }

    // MARK: Public Instance Properties

    /// The string value of this part ID.
    public let stringValue: String
}

// MARK: - UniqueID

extension PartID: UniqueID {

    // MARK: Public Type Properties

    public nonisolated(unsafe) static let validPattern = /P\$[0-9A-Za-z]{22}/

    public static let validPrefix = "P$"
}
