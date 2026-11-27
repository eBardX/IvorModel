// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

/// A unique ID for a ``Strand``, represented as a validated string.
///
/// Persisted with the strand, so a strand keeps its identity across a save and reopen, and
/// anything that refers to it by ID still does. A strand’s ID is unique within its ``Work``; a
/// duplicated work’s strands keep theirs, so the same ID may appear in more than one work.
public struct StrandID {

    // MARK: Public Initializers

    /// Creates a strand ID from a string value already known to be valid.
    ///
    /// - Parameter stringValue:    The string identifying the strand.
    public init(uncheckedStringValue stringValue: String) {
        self.stringValue = stringValue
    }

    // MARK: Public Instance Properties

    /// The string value of this strand ID.
    public let stringValue: String
}

// MARK: - UniqueID

extension StrandID: UniqueID {

    // MARK: Public Type Properties

    public nonisolated(unsafe) static let validPattern = /S\$[0-9A-Za-z]{22}/

    public static let validPrefix = "S$"
}
