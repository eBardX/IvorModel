internal import IvorTiming
internal import XestiNumbers
internal import XestiTools

extension TempoMap {

    // MARK: Internal Nested Types

    internal struct Entry {
        internal var beatDuration: BeatDuration
        internal let beatTime: BeatTime
        internal let extras: Extras?
        internal let tempo: Tempo
        internal var tempoDelta: Number
        internal var wallDuration: WallDuration
        internal var wallTime: WallTime
    }
}

// MARK: -

extension TempoMap.Entry {

    // MARK: Internal Initializers

    internal init(beatTime: BeatTime,
                  tempo: Tempo,
                  extras: Extras?) {
        self.beatDuration = 0
        self.beatTime = beatTime
        self.extras = extras
        self.tempo = tempo
        self.tempoDelta = 0
        self.wallDuration = 0
        self.wallTime = 0
    }
}

// MARK: - Codable

extension TempoMap.Entry: Codable {

    // MARK: Internal Initializers

    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let beatTime = try container.decode(BeatTime.self)
        let tempo = try container.decode(Tempo.self)
        let extras = try container.decodeIfPresent(Extras.self)

        self.init(beatTime: beatTime,
                  tempo: tempo,
                  extras: extras)
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(beatTime)
        try container.encode(tempo)

        if let extras {
            try container.encode(extras)
        }
    }
}

// MARK: - Comparable

extension TempoMap.Entry: Comparable {

    // MARK: Internal Type Methods

    internal static func < (lhs: Self,
                            rhs: Self) -> Bool {
        lhs.beatTime < rhs.beatTime
    }
}

// MARK: - Sendable

extension TempoMap.Entry: Sendable {
}
