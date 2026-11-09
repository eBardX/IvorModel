// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension Template {

    // MARK: Public Nested Types

    /// The setting a template’s first source part started in: its dynamic level, instrument and
    /// pan position, and — in beat time — its work’s tempo.
    ///
    /// Analysis learns only pitches and durations; the source context carries the rest of the
    /// source’s starting setting over, so that a generated work starts out sounding like its
    /// source. Each value is the one in effect at the part’s first attack, or at time zero if the
    /// part has no notes.
    public struct SourceContext {

        // MARK: Public Initializers

        /// Creates a new source context.
        ///
        /// Each value defaults to the one an empty map of its kind gives.
        ///
        /// - Parameter dynamic:    The dynamic level. Defaults to `.mp`.
        /// - Parameter instrument: The instrument. Defaults to `.vanilla`.
        /// - Parameter pan:        The pan position. Defaults to `.center`.
        /// - Parameter tempo:      The tempo, or `nil` for a wall-time source. Defaults to `nil`.
        public init(dynamic: Dynamic = DynamicMap<BeatTime>().defaultDynamic,
                    instrument: Instrument = InstrumentTable<BeatTime>().defaultInstrument,
                    pan: Pan = PanMap<BeatTime>().defaultPan,
                    tempo: Tempo? = nil) {
            self.dynamic = dynamic
            self.instrument = instrument
            self.pan = pan
            self.tempo = tempo
        }

        // MARK: Public Instance Properties

        /// The dynamic level.
        public let dynamic: Dynamic

        /// The instrument.
        public let instrument: Instrument

        /// The pan position.
        public let pan: Pan

        /// The tempo, or `nil` for a wall-time source.
        public let tempo: Tempo?
    }
}

// MARK: -

extension Template.SourceContext {

    // MARK: Internal Initializers

    //
    // The setting of the part at `index` of `content` at its first attack — or the defaults, if
    // there's no such part.
    //
    internal init(content: Work.Content,
                  index: Int) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            self.init(parts: parts,
                      index: index) { tempoMap[$0] }

        case let .absoluteWall(parts):
            self.init(parts: parts,
                      index: index) { _ in nil }

        case let .keyboardBeat(parts, tempoMap):
            self.init(parts: parts,
                      index: index) { tempoMap[$0] }

        case let .keyboardWall(parts):
            self.init(parts: parts,
                      index: index) { _ in nil }

        case let .standardBeat(parts, tempoMap):
            self.init(parts: parts,
                      index: index) { tempoMap[$0] }

        case let .standardWall(parts):
            self.init(parts: parts,
                      index: index) { _ in nil }
        }
    }

    // MARK: Internal Instance Methods

    //
    // A new part, named `name`, with `noteTable` and maps that start out in this setting.  A value
    // that an empty map already gives is left to it, so that the maps stay empty where they can.
    //
    internal func part<T, P>(name: String,
                             noteTable: NoteTable<T, P>) -> Part<T, P> {
        var dynamicMap = DynamicMap<T>()
        var instrumentTable = InstrumentTable<T>()
        var panMap = PanMap<T>()

        if dynamic != dynamicMap.defaultDynamic {
            dynamicMap.insert(time: .zero,
                              dynamic: dynamic)
        }

        if instrument != instrumentTable.defaultInstrument {
            instrumentTable.insert(time: .zero,
                                   instrument: instrument)
        }

        if pan != panMap.defaultPan {
            panMap.insert(time: .zero,
                          pan: pan)
        }

        return Part(name: name,
                    noteTable: noteTable,
                    dynamicMap: dynamicMap,
                    instrumentTable: instrumentTable,
                    panMap: panMap)
    }

    //
    // A tempo map that starts out at this setting's tempo, or an empty one if it has none or it's
    // the default.
    //
    internal func tempoMap() -> TempoMap {
        var tempoMap = TempoMap()

        if let tempo, tempo != tempoMap.defaultTempo {
            tempoMap.insert(beatTime: .zero,
                            tempo: tempo)
        }

        return tempoMap
    }

    // MARK: Private Initializers

    //
    // `tempo` gives the tempo in effect at a time, or `nil` in wall time.
    //
    private init<T>(parts: [Part<T, some Any>],
                    index: Int,
                    tempo: (T) -> Tempo?) {
        guard parts.indices.contains(index)
        else { self.init(tempo: tempo(.zero)); return }

        let part = parts[index]
        let time = part.timeRange?.lowerBound ?? .zero

        self.init(dynamic: part.dynamicMap[time],
                  instrument: part.instrumentTable[time],
                  pan: part.panMap[time],
                  tempo: tempo(time))
    }
}

// MARK: - Codable

extension Template.SourceContext: Codable {
}

// MARK: - Hashable

extension Template.SourceContext: Hashable {
}

// MARK: - Sendable

extension Template.SourceContext: Sendable {
}
