public import XestiTools

public struct PartID: IntRepresentable {

    // MARK: Public Type Methods

    public static func isValid(_ intValue: Int) -> Bool {
        intValue > 0
    }

    // MARK: Public Initializers

    public init?(intValue: Int) {
        guard Self.isValid(intValue)
        else { return nil }

        self.intValue = intValue
    }

    // MARK: Public Instance Properties

    public let intValue: Int
}

// MARK: - (conversion)

extension PartID {

    // MARK: Public Initializers

    public init?(index: Int) {
        self.init(intValue: index + 1)
    }

    // MARK: Public Instance Properties

    public var index: Int {
        intValue - 1
    }
}
