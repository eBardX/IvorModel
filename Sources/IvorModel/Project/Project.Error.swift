public import XestiTools

extension Project {
    public enum Error {
        case corruptedProject
        case loadFailure((any EnhancedError)?)
        case saveFailure((any EnhancedError)?)
        case unsupportedVersion(Int)
    }
}

// MARK: - EnhancedError

extension Project.Error: EnhancedError {
    public var category: Category? {
        Category("IvorModel")
    }

    public var cause: (any EnhancedError)? {
        switch self {
        case let .loadFailure(error),
            let .saveFailure(error):
            error

        default:
            nil
        }
    }

    public var message: String {
        switch self {
        case .corruptedProject:
            "Project is corrupted!"

        case .loadFailure:
            "Unable to load Ivor project"

        case .saveFailure:
            "Unable to save Ivor project"

        case let .unsupportedVersion(version):
            "Unsupported Ivor manifest version: \(version)"
        }
    }
}

// MARK: - Sendable

extension Project.Error: Sendable {
}
