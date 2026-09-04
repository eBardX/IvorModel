// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

private import Foundation

extension PanMap {

    /// A stable identity for a single entry in a ``PanMap``, represented as a
    /// validated string.
    ///
    /// An entry's time, pan position, and extras can all change — via
    /// ``PanMap/update(entryID:pan:extras:)`` or ``PanMap/move(entryID:to:)`` — without
    /// affecting its identity, so a caller can keep addressing the same entry across
    /// an edit that reorders it, rather than recomputing which ordinal position it
    /// landed on.
    ///
    /// Not persisted: `PanMap.Entry`'s `Codable` conformance never encodes an
    /// entry's identity, and assigns every decoded entry a fresh one, the same as a
    /// newly inserted entry. An entry's identity is therefore stable only within one
    /// in-memory pan map's lifetime — never across an encode/decode round trip, and
    /// so never across a save and reopen.
    public struct EntryID: StringRepresentable {

        // MARK: Public Initializers

        /// Creates a new, unique entry identity.
        public init() {
            self.init(Self.validPrefix + UUID().base62String)
        }

        /// Creates an entry identity from a string value, returning `nil` if the
        /// string is invalid.
        ///
        /// - Parameter stringValue:    The string identifying the entry.
        public init?(stringValue: String) {
            guard Self.isValid(stringValue)
            else { return nil }

            self.stringValue = stringValue
        }

        // MARK: Public Instance Properties

        /// The string value of this entry identity.
        public let stringValue: String
    }
}

// MARK: -

extension PanMap.EntryID {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given string is a valid entry
    /// identity.
    ///
    /// - Parameter stringValue:    The string to validate.
    ///
    /// - Returns:  `true` if `stringValue` is valid; otherwise, `false`.
    public static func isValid(_ stringValue: String) -> Bool {
        stringValue.wholeMatch(of: validPattern) != nil
    }

    // MARK: Private Type Properties

    //
    // Computed, not stored — `EntryID` is nested inside the generic `PanMap<TimeType>`,
    // and Swift doesn't allow stored static properties on a type nested in a generic
    // context, even though this one doesn't itself depend on `TimeType`.
    //
    private static var validPattern: Regex<Substring> {
        /E\$[0-9A-Za-z]{22}/
    }

    private static var validPrefix: String {
        "E$"
    }
}
