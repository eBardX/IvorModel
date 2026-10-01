// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Project {
    /// An error thrown by ``Project`` operations.
    public enum Error {
        /// The project data is corrupted and cannot be read.
        case corruptedProject

        /// A failure that occurred while loading the project.
        case loadFailure((any EnhancedError)?)

        /// A failure that occurred while saving the project.
        case saveFailure((any EnhancedError)?)

        /// The template is locked, so it cannot be removed.
        case templateIsLocked(TemplateID)

        /// The project was encoded with an unsupported version number.
        case unsupportedVersion(Int)

        /// The work is locked, so it cannot be removed.
        case workIsLocked(WorkID)
    }
}

// MARK: - EnhancedError

extension Project.Error: EnhancedError {
    /// The error category for this error.
    public var category: Category? {
        Category("IvorModel")
    }

    /// The underlying error that caused this error, if any.
    public var cause: (any EnhancedError)? {
        switch self {
        case let .loadFailure(error),
            let .saveFailure(error):
            error

        default:
            nil
        }
    }

    /// The human-readable message for this error.
    public var message: String {
        switch self {
        case .corruptedProject:
            "Project is corrupted!"

        case .loadFailure:
            "Unable to load Ivor project"

        case .saveFailure:
            "Unable to save Ivor project"

        case let .templateIsLocked(templateID):
            "Template \(templateID.stringValue) is locked and cannot be removed."

        case let .unsupportedVersion(version):
            "Unsupported Ivor manifest version: \(version)"

        case let .workIsLocked(workID):
            "Work \(workID.stringValue) is locked and cannot be removed."
        }
    }
}

// MARK: - Sendable

extension Project.Error: Sendable {
}
