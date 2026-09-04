// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

private import Foundation

/// A unique ID for a ``Part``, represented as a validated string.
///
/// Not persisted: `Part`'s `Codable` conformance never encodes its identity, and
/// assigns every decoded part a fresh one, the same as a newly inserted part. A
/// part's identity is therefore stable only within one in-memory project's
/// lifetime — never across an encode/decode round trip, and so never across a save
/// and reopen.
public struct PartID: StringRepresentable {

    // MARK: Public Initializers

    /// Creates a new, unique part ID.
    public init() {
        self.init(Self.validPrefix + UUID().base62String)
    }

    /// Creates a part ID from a string value, returning `nil` if the string is invalid.
    ///
    /// - Parameter stringValue:    The string identifying the part.
    public init?(stringValue: String) {
        guard Self.isValid(stringValue)
        else { return nil }

        self.stringValue = stringValue
    }

    // MARK: Public Instance Properties

    /// The string value of this part ID.
    public let stringValue: String
}

// MARK: -

extension PartID {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the provided string is a valid part ID.
    ///
    /// - Parameter stringValue:    The string to validate.
    ///
    /// - Returns:  `true` if `stringValue` is valid; otherwise, `false`.
    public static func isValid(_ stringValue: String) -> Bool {
        stringValue.wholeMatch(of: validPattern) != nil
    }

    // MARK: Private Type Properties

    private nonisolated(unsafe) static let validPattern = /P\$[0-9A-Za-z]{22}/

    private static let validPrefix = "P$"
}
