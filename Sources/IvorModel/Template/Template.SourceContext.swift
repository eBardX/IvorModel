// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Template {

    // MARK: Public Nested Types

    /// The setting a template’s first source started in: its dynamic level, instrument and
    /// pan position, and — in beat time — its work’s tempo, meter and key, and where in
    /// the bar it started.
    ///
    /// Analysis learns only pitches and durations; the source context carries the rest of the
    /// source’s starting setting over, so that a generated work starts out sounding like its
    /// source. Each value is the one in effect at the source’s first attack (the first of the
    /// notes it chose, from any of its strands), or at time zero if it has no notes. The dynamic
    /// and instrument are read through the strand that attack belongs to — its own dynamic map
    /// and instrument table if it has them, the part’s otherwise — or, where several strands
    /// attack first together, through the first of them in score order.
    public struct SourceContext {

        // MARK: Public Initializers

        /// Creates a new source context.
        ///
        /// Each value defaults to the one an empty map of its kind gives.
        ///
        /// - Parameter dynamic:        The dynamic level. Defaults to `.mp`.
        /// - Parameter instrument:     The instrument. Defaults to `.vanilla`.
        /// - Parameter pan:            The pan position. Defaults to `.center`.
        /// - Parameter tempo:          The tempo, or `nil` for a wall-time source. Defaults to
        ///                             `nil`.
        /// - Parameter meter:          The meter, or `nil` for a source with no meter there.
        ///                             Defaults to `nil`.
        /// - Parameter key:            The key, or `nil` for a source with no key
        ///                             there. Defaults to `nil`.
        /// - Parameter barPosition:    The distance from the start of the bar to the first
        ///                             attack, in whole notes. Defaults to 0.
        public init(dynamic: Dynamic = DynamicMap<BeatTime>().defaultDynamic,
                    instrument: Instrument = InstrumentTable<BeatTime>().defaultInstrument,
                    pan: Pan = PanMap<BeatTime>().defaultPan,
                    tempo: Tempo? = nil,
                    meter: Meter? = nil,
                    key: Key? = nil,
                    barPosition: BeatDuration = .zero) {
            self.barPosition = barPosition
            self.dynamic = dynamic
            self.instrument = instrument
            self.key = key
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

        /// The key in effect at the first attack: `nil` for a wall-time source, a source
        /// with no key there, or one analyzed with variants that change its key
        /// (inverted, or transposed other than by octaves), whose template then fits no one key.
        public let key: Key?

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
    // The setting of `source` in `content` at its first attack — or the defaults, if its part
    // isn't there. The key is left out unless `keepsKey` is set.
    //
    internal init(content: Work.Content,
                  source: Template.SourceScope,
                  keepsKey: Bool = true) {
        switch content.cases {
        case let .absoluteBeat(parts, tempoMap, meterTable, keyTable):
            self.init(parts: parts,
                      source: source,
                      tempo: { tempoMap[$0] },
                      barOffset: { meterTable.barOffset(at: $0) },
                      key: { keepsKey ? keyTable.key(at: $0) : nil })

        case let .absoluteWall(parts):
            self.init(parts: parts,
                      source: source,
                      tempo: { _ in nil },
                      barOffset: { _ in nil },
                      key: { _ in nil })

        case let .keyboardBeat(parts, tempoMap, meterTable, keyTable):
            self.init(parts: parts,
                      source: source,
                      tempo: { tempoMap[$0] },
                      barOffset: { meterTable.barOffset(at: $0) },
                      key: { keepsKey ? keyTable.key(at: $0) : nil })

        case let .keyboardWall(parts):
            self.init(parts: parts,
                      source: source,
                      tempo: { _ in nil },
                      barOffset: { _ in nil },
                      key: { _ in nil })

        case let .standardBeat(parts, tempoMap, meterTable, keyTable):
            self.init(parts: parts,
                      source: source,
                      tempo: { tempoMap[$0] },
                      barOffset: { meterTable.barOffset(at: $0) },
                      key: { keepsKey ? keyTable.key(at: $0) : nil })

        case let .standardWall(parts):
            self.init(parts: parts,
                      source: source,
                      tempo: { _ in nil },
                      barOffset: { _ in nil },
                      key: { _ in nil })
        }
    }

    // MARK: Internal Instance Methods

    //
    // A key table with this setting's key at 0, or an empty one if it has
    // none.
    //
    internal func keyTable() -> KeyTable {
        var keyTable = KeyTable()

        if let key {
            _ = try? keyTable.insert(beatTime: .zero,
                                     key: key)
        }

        return keyTable
    }

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
    // `tempo` gives the tempo in effect at a time, `barOffset` the meter and the distance from
    // the start of its bar, and `key` the key; each gives `nil` in wall time.
    //
    private init<T>(parts: [Part<T, some Any>],
                    source: Template.SourceScope,
                    tempo: (T) -> Tempo?,
                    barOffset: (T) -> (meter: Meter, offset: BeatDuration)?,
                    key: (T) -> Key?) {
        let notes = source.notes(in: parts)
        let time = notes?.noteTable.timeRange?.lowerBound ?? .zero
        let meterContext = barOffset(time)

        guard let notes
        else {
            self.init(tempo: tempo(time),
                      meter: meterContext?.meter,
                      key: key(time),
                      barPosition: meterContext?.offset ?? .zero)
            return
        }

        let leadingStrand = notes.leadingStrand

        self.init(dynamic: notes.part.dynamicMap(for: leadingStrand)[time],
                  instrument: notes.part.instrumentTable(for: leadingStrand)[time],
                  pan: notes.part.panMap[time],
                  tempo: tempo(time),
                  meter: meterContext?.meter,
                  key: key(time),
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
