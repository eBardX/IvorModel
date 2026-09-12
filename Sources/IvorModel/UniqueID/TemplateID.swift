// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

/// A unique ID for a ``Template``, represented as a validated string.
public struct TemplateID {

    // MARK: Public Initializers

    /// Creates a template ID from a string value already known to be valid.
    ///
    /// - Parameter stringValue:    The string identifying the template.
    public init(uncheckedStringValue stringValue: String) {
        self.stringValue = stringValue
    }

    // MARK: Public Instance Properties

    /// The string value of this template ID.
    public let stringValue: String
}

// MARK: - UniqueID

extension TemplateID: UniqueID {

    // MARK: Public Type Properties

    public nonisolated(unsafe) static let validPattern = /T\$[0-9A-Za-z]{22}/

    public static let validPrefix = "T$"
}
