// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension Template {

    // MARK: Public Nested Types

    /// The setting a template’s first source part started in: its dynamic level, instrument and
    /// pan position, and — in beat time — its work’s tempo and meter, and where in the bar it
    /// started.
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
        /// - Parameter tempo:          The tempo, or `nil` for a wall-time source. Defaults to
        ///                             `nil`.
        /// - Parameter meter:          The meter, or `nil` for a source with no meter there.
        ///                             Defaults to `nil`.
        /// - Parameter barPosition:    The distance from the start of the bar to the first
        ///                             attack, in whole notes. Defaults to 0.
        public init(dynamic: Dynamic = DynamicMap<BeatTime>().defaultDynamic,
                    instrument: Instrument = InstrumentTable<BeatTime>().defaultInstrument,
                    pan: Pan = PanMap<BeatTime>().defaultPan,
                    tempo: Tempo? = nil,
                    meter: Meter? = nil,
                    barPosition: BeatDuration = .zero) {
            self.barPosition = barPosition
            self.dynamic = dynamic
            self.instrument = instrument
            self.meter = meter
            self.pan = pan
            self.tempo = tempo
        }

        // MARK: Public Instance Properties

        /// The distance, in whole notes, from the start of the bar that contains the first attack
        /// to the attack itself. A pickup bar counts as the tail of a full bar. It’s 0 whenever
        /// ``meter`` is `nil` or free.
        public let barPosition: BeatDuration

        /// The dynamic level.
        public let dynamic: Dynamic

        /// The instrument.
        public let instrument: Instrument

        /// The meter in effect at the first attack: `nil` for a wall-time source, a source with
        /// an empty meter table, or one whose first attack comes before the table’s first entry.
        public let meter: Meter?

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
        case let .absoluteBeat(parts, tempoMap, meterTable):
            self.init(parts: parts,
                      index: index,
                      tempo: { tempoMap[$0] },
                      barOffset: { meterTable.barOffset(at: $0) })

        case let .absoluteWall(parts):
            self.init(parts: parts,
                      index: index,
                      tempo: { _ in nil },
                      barOffset: { _ in nil })

        case let .keyboardBeat(parts, tempoMap, meterTable):
            self.init(parts: parts,
                      index: index,
                      tempo: { tempoMap[$0] },
                      barOffset: { meterTable.barOffset(at: $0) })

        case let .keyboardWall(parts):
            self.init(parts: parts,
                      index: index,
                      tempo: { _ in nil },
                      barOffset: { _ in nil })

        case let .standardBeat(parts, tempoMap, meterTable):
            self.init(parts: parts,
                      index: index,
                      tempo: { tempoMap[$0] },
                      barOffset: { meterTable.barOffset(at: $0) })

        case let .standardWall(parts):
            self.init(parts: parts,
                      index: index,
                      tempo: { _ in nil },
                      barOffset: { _ in nil })
        }
    }

    // MARK: Internal Instance Methods

    //
    // A meter table that starts out in this setting's meter at 0, with a pickup that puts the
    // first attack as far into its bar as the source's was, or an empty one if it has no meter.
    // For example, a source that started on beat 3 of 3/4 gives a one-beat pickup.
    //
    internal func meterTable() -> MeterTable {
        var meterTable = MeterTable()

        guard let meter
        else { return meterTable }

        _ = try? meterTable.insert(beatTime: .zero,
                                   meter: meter)

        if let barLength = meter.barLength,
           !barPosition.isZero {
            try? meterTable.setPickup(Meter.remainder(barLength - barPosition,
                                                      barLength))
        }

        return meterTable
    }

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

        //
        // A generated part starts with every pedal up: the source's pedal state isn't captured.
        //
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
    // `tempo` gives the tempo in effect at a time, and `barOffset` the meter and the distance from
    // the start of its bar; each gives `nil` in wall time.
    //
    private init<T>(parts: [Part<T, some Any>],
                    index: Int,
                    tempo: (T) -> Tempo?,
                    barOffset: (T) -> (meter: Meter, offset: BeatDuration)?) {
        let part = parts.indices.contains(index) ? parts[index] : nil
        let time = part?.timeRange?.lowerBound ?? .zero
        let meterContext = barOffset(time)

        guard let part
        else {
            self.init(tempo: tempo(time),
                      meter: meterContext?.meter,
                      barPosition: meterContext?.offset ?? .zero)
            return
        }

        self.init(dynamic: part.dynamicMap[time],
                  instrument: part.instrumentTable[time],
                  pan: part.panMap[time],
                  tempo: tempo(time),
                  meter: meterContext?.meter,
                  barPosition: meterContext?.offset ?? .zero)
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
