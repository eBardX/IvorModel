public import XestiTools

private import Foundation

public struct TemplateID: StringRepresentable {

    // MARK: Public Type Methods

    public static func isValid(_ stringValue: String) -> Bool {
        stringValue.wholeMatch(of: validPattern) != nil
    }

    // MARK: Public Initializers

    public init?(stringValue: String) {
        guard Self.isValid(stringValue)
        else { return nil }

        self.stringValue = stringValue
    }

    // MARK: Public Instance Properties

    public let stringValue: String

    // MARK: Private Type Properties

    private nonisolated(unsafe) static let validPattern = /T\$[0-9A-Za-z]{22}/

    private static let validPrefix = "T$"
}

// MARK: - (convenience)

extension TemplateID {

    // MARK: Public Initializers

    public init() {
        self.init(Self.validPrefix + UUID().base62String)
    }
}
