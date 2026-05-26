// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers
public import XestiTools

extension NoteTable {
    /// An error thrown by ``NoteTable`` operations.
    public enum Error {
        /// A failure that occurred while augmenting a note.
        case augmentFailure(TimeType, DurationType, PitchType, PitchType)

        /// A failure that occurred while diminishing a note.
        case diminishFailure(TimeType, DurationType, PitchType, PitchType)

        /// An augmentation factor that is not a positive rational number ≥ 1.
        case invalidAugmentationFactor(Number)

        /// A diminution factor that is not a positive rational number ≥ 1.
        case invalidDiminutionFactor(Number)

        /// A quantization factor that is not a positive integer.
        case invalidQuantizationFactor(Int)

        /// A failure that occurred while inverting a note.
        case invertFailure(TimeType, DurationType, PitchType, PitchType)

        /// A failure that occurred while moving a note.
        case moveFailure(TimeType, DurationType, PitchType, PitchType)

        /// A failure that occurred while reversing a note.
        case reverseFailure(TimeType, DurationType, PitchType, PitchType)

        /// A failure that occurred while transposing a note.
        case transposeFailure(TimeType, DurationType, PitchType, PitchType)
    }
}

// MARK: - EnhancedError

extension NoteTable.Error: EnhancedError {
    /// The error category for this error.
    public var category: Category? {
        Category("IvorModel")
    }

    /// The human-readable message for this error.
    public var message: String {
        switch self {
        case let .augmentFailure(attack, duration, startPitch, endPitch):
            "Unable to augment note table note, \(_formatNote(attack, duration, startPitch, endPitch))"

        case let .diminishFailure(attack, duration, startPitch, endPitch):
            "Unable to diminish note table note, \(_formatNote(attack, duration, startPitch, endPitch))"

        case let .invalidAugmentationFactor(factor):
            "Invalid augmentation factor: \(factor)"

        case let .invalidDiminutionFactor(factor):
            "Invalid diminution factor: \(factor)"

        case let .invalidQuantizationFactor(factor):
            "Invalid quantization factor: \(factor)"

        case let .invertFailure(attack, duration, startPitch, endPitch):
            "Unable to invert note table note, \(_formatNote(attack, duration, startPitch, endPitch))"

        case let .moveFailure(attack, duration, startPitch, endPitch):
            "Unable to move note table note, \(_formatNote(attack, duration, startPitch, endPitch))"

        case let .reverseFailure(attack, duration, startPitch, endPitch):
            "Unable to reverse note table note, \(_formatNote(attack, duration, startPitch, endPitch))"

        case let .transposeFailure(attack, duration, startPitch, endPitch):
            "Unable to transpose note table note, \(_formatNote(attack, duration, startPitch, endPitch))"
        }
    }

    // MARK: Private Instance Methods

    private func _formatNote(_ attack: TimeType,
                             _ duration: NoteTable.DurationType,
                             _ startPitch: PitchType,
                             _ endPitch: PitchType) -> String {
        if startPitch != endPitch {
            "attack: \(attack), duration: \(duration), startPitch: \(startPitch), endPitch: \(endPitch)"
        } else {
            "attack: \(attack), duration: \(duration), pitch: \(startPitch)"
        }
    }
}

// MARK: - Sendable

extension NoteTable.Error: Sendable {
}
