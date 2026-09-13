// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

/// A unique ID for a ``Part``, represented as a validated string.
///
/// Not persisted: `Part`’s `Codable` conformance never encodes its identity, and
/// assigns every decoded part a fresh one, the same as a newly inserted part. A
/// part’s identity is therefore stable only within one in-memory project’s
/// lifetime — never across an encode/decode round trip, and so never across a save
/// and reopen.
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
