public import XestiNumbers
public import XestiTools

extension NoteTable {
    public enum Error {
        case augmentFailure(TimeType, DurationType, PitchType, PitchType)
        case diminishFailure(TimeType, DurationType, PitchType, PitchType)
        case invalidAugmentationFactor(Number)
        case invalidDiminutionFactor(Number)
        case invalidQuantizationFactor(Int)
        case invertFailure(TimeType, DurationType, PitchType, PitchType)
        case moveFailure(TimeType, DurationType, PitchType, PitchType)
        case reverseFailure(TimeType, DurationType, PitchType, PitchType)
        case transposeFailure(TimeType, DurationType, PitchType, PitchType)
    }
}

// MARK: - EnhancedError

extension NoteTable.Error: EnhancedError {
    public var category: Category? {
        Category("IvorModel")
    }

    public var message: String {
        switch self {
        case let .augmentFailure(att, dur, spit, epit):
            "Unable to augment note table note, \(_formatNote(att, dur, spit, epit))"

        case let .diminishFailure(att, dur, spit, epit):
            "Unable to diminish note table note, \(_formatNote(att, dur, spit, epit))"

        case let .invalidAugmentationFactor(factor):
            "Invalid augmentation factor: \(factor)"

        case let .invalidDiminutionFactor(factor):
            "Invalid diminution factor: \(factor)"

        case let .invalidQuantizationFactor(factor):
            "Invalid quantization factor: \(factor)"

        case let .invertFailure(att, dur, spit, epit):
            "Unable to invert note table note, \(_formatNote(att, dur, spit, epit))"

        case let .moveFailure(att, dur, spit, epit):
            "Unable to move note table note, \(_formatNote(att, dur, spit, epit))"

        case let .reverseFailure(att, dur, spit, epit):
            "Unable to reverse note table note, \(_formatNote(att, dur, spit, epit))"

        case let .transposeFailure(att, dur, spit, epit):
            "Unable to transpose note table note, \(_formatNote(att, dur, spit, epit))"
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
