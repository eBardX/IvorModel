// © 2026 John Gary Pusey (see LICENSE.md)

private import XestiTools

/// A sound on a synthesizer: what an ``Instrument`` — which only designates an instrument — is
/// realized as when a part plays.
///
/// A patch is either a General MIDI instrument (Level 1 or Level 2), a General MIDI percussion
/// kit or drum set, or a custom program and bank, such as one on a hardware synthesizer that
/// doesn’t follow General MIDI. See ``Kind``.
///
/// It says what to play, not where: which synthesizer, or MIDI destination, a part plays
/// through is up to the app.
public struct Patch {

    // MARK: Public Initializers

    /// Creates a patch of the given kind, returning `nil` if any of its numbers is out of range.
    ///
    /// A custom patch’s name has its whitespace normalized to a single line, and becomes `nil`
    /// if it is then empty.
    ///
    /// - Parameter kind:   The kind of sound, and the numbers that select it.
    public init?(_ kind: Kind) {
        switch kind {
        case let .custom(program, bank, name):
            guard Self._isValidProgram(program),
                  bank.map(Self._isValidCustomBank) ?? true
            else { return nil }

            self.kind = .custom(program: program,
                                bank: bank,
                                name: name?.normalizingWhitespace().nilIfEmpty)

        case let .generalMIDI1(program),
             let .generalMIDI2DrumSet(program):
            guard Self._isValidProgram(program)
            else { return nil }

            self.kind = kind

        case .generalMIDI1Percussion:
            self.kind = kind

        case let .generalMIDI2(program, variation):
            guard Self._isValidProgram(program),
                  Self._isValidVariation(variation)
            else { return nil }

            self.kind = kind
        }
    }

    // MARK: Public Instance Properties

    /// The kind of sound this patch selects, and the numbers that select it.
    public let kind: Kind
}

// MARK: -

extension Patch {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether this patch is a percussion kit or drum set, whose
    /// keys each play a different sound.
    public var isPercussion: Bool {
        switch kind {
        case .generalMIDI1Percussion,
             .generalMIDI2DrumSet:
            true

        case .custom,
             .generalMIDI1,
             .generalMIDI2:
            false
        }
    }

    // MARK: Private Type Methods

    private static func _isValidCustomBank(_ bank: Int) -> Bool {
        (0...16_383).contains(bank)
    }

    private static func _isValidProgram(_ program: Int) -> Bool {
        (1...128).contains(program)
    }

    private static func _isValidVariation(_ variation: Int) -> Bool {
        (0...127).contains(variation)
    }
}

// MARK: - Codable

extension Patch: Codable {

    // MARK: Public Initializers

    /// Creates a patch by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted, or if any of the
    ///             patch’s numbers is out of range.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let kind = try container.decode(Kind.self)

        guard let patch = Self(kind)
        else { throw DecodingError.dataCorruptedError(in: container,
                                                      debugDescription: "Invalid patch: \(kind)") }

        self = patch
    }

    // MARK: Public Instance Methods

    /// Encodes this patch into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(kind)
    }
}

// MARK: - Hashable

extension Patch: Hashable {
}

// MARK: - Sendable

extension Patch: Sendable {
}
