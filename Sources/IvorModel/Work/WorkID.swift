public import XestiTools

private import Foundation

public struct WorkID: StringRepresentable {

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

    private nonisolated(unsafe) static let validPattern = /W\$[0-9A-Za-z]{22}/

    private static let validPrefix = "W$"
}

// MARK: - (convenience)

extension WorkID {

    // MARK: Public Initializers

    public init() {
        self.init(Self.validPrefix + UUID().base62String)
    }
}
