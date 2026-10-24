// © 2026 John Gary Pusey (see LICENSE.md)

extension PatchTable {

    // MARK: Public Nested Types

    /// How an ``Instrument`` is realized when a part plays: the ``Patch`` it sounds as and,
    /// optionally, the MIDI channel it plays on.
    ///
    /// Giving each of a part’s instruments a channel of its own lets the part change instruments
    /// without changing programs as it plays, so notes held across the change keep their sound.
    ///
    /// The channel is a preference, not a guarantee: the app may play the instrument on another
    /// channel when it must — to keep parts from clashing, say.
    public struct Assignment {

        // MARK: Public Initializers

        /// Creates a patch assignment, returning `nil` if the channel is out of range.
        ///
        /// - Parameter patch:      The patch the instrument sounds as.
        /// - Parameter channel:    The MIDI channel (1–16) the instrument prefers to play on, or
        ///                         `nil` to play on whichever channel the app gives the part.
        ///                         Defaults to `nil`.
        public init?(patch: Patch,
                     channel: Int? = nil) {
            guard channel.map(Self._isValidChannel) ?? true
            else { return nil }

            self.channel = channel
            self.patch = patch
        }

        // MARK: Public Instance Properties

        /// The MIDI channel (1–16) the instrument prefers to play on, or `nil` to play on whichever
        /// channel the app gives the part.
        public let channel: Int?

        /// The patch the instrument sounds as.
        public let patch: Patch
    }
}

// MARK: -

extension PatchTable.Assignment {

    // MARK: Private Type Methods

    private static func _isValidChannel(_ channel: Int) -> Bool {
        (1...16).contains(channel)
    }
}

// MARK: - Codable

extension PatchTable.Assignment: Codable {

    // MARK: Public Initializers

    /// Creates a patch assignment by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted, or if the channel
    ///             is out of range.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let channel = try container.decodeIfPresent(Int.self,
                                                    forKey: .channel)

        let patch = try container.decode(Patch.self,
                                         forKey: .patch)

        guard let assignment = Self(patch: patch,
                                    channel: channel)
        else { throw DecodingError.dataCorruptedError(forKey: .channel,
                                                      in: container,
                                                      debugDescription: "Invalid channel: \(channel ?? 0)") }

        self = assignment
    }

    // MARK: Public Instance Methods

    /// Encodes this patch assignment into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(patch,
                             forKey: .patch)

        try container.encodeIfPresent(channel,
                                      forKey: .channel)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case channel
        case patch
    }
}

// MARK: - Hashable

extension PatchTable.Assignment: Hashable {
}

// MARK: - Sendable

extension PatchTable.Assignment: Sendable {
}
