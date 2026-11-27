// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiNumbers

//
// Reads every fermata and caesura in a work's parts — fermatas on notes, fermata marks and
// caesura marks — as the holds and pauses they add (see `TimelineHold` and `TimelinePause`).
//
// A fermata's hold comes from its execution, else its part's rules for its shape, else the
// built-in stretch for its shape; it lasts that much longer, converted at the local tempo in a
// beat work. Its pause after comes from its execution, else the rules; there's none by default.
// A fermata that isn't played adds nothing. A caesura's pause comes from its execution, else the
// rules, else 2 seconds.
//
internal struct HoldCollector<TimeType: RenderableTime, PitchType: PitchProtocol> {

    // MARK: Internal Initializers

    internal init(parts: [Part<TimeType, PitchType>],
                  workRules: InterpretationRules?,
                  clock: RenderingClock) {
        var collector = Self(clock: clock)

        for (index, part) in parts.enumerated() {
            let rules = InterpretationRules.resolved(work: workRules,
                                                     part: part.interpretationRules)

            for strand in part.strands {
                for note in strand.noteTable {
                    if let fermata = note.ornamentation?.fermata {
                        collector._add(fermata,
                                       at: note.attack.number,
                                       span: TimeType.number(of: note.duration),
                                       part: index,
                                       noteID: note.noteID,
                                       rules: rules.fermata)
                    }
                }
            }

            for entry in part.markTable {
                switch entry.mark {
                case let .caesura(execution):
                    collector._addCaesura(execution,
                                          at: entry.time.number,
                                          rules: rules)

                case let .fermata(fermata, span):
                    collector._add(fermata,
                                   at: entry.time.number,
                                   span: TimeType.number(of: span.duration),
                                   part: index,
                                   noteID: nil,
                                   rules: rules.fermata)
                }
            }
        }

        self = collector
    }

    // MARK: Internal Instance Properties

    //
    // The start of every fermata's span, played or not, each once, in order.
    //
    internal var fermataTimes: [Number]

    internal var holds: [TimelineHold]
    internal var pauses: [TimelinePause]

    // MARK: Private Initializers

    private init(clock: RenderingClock) {
        self.clock = clock
        self.fermataTimes = []
        self.holds = []
        self.pauses = []
    }

    // MARK: Private Instance Properties

    private let clock: RenderingClock
}

// MARK: -

extension HoldCollector {

    // MARK: Private Instance Methods

    private mutating func _add(_ fermata: Fermata<TimeType>,
                               at time: Number,
                               span: Number,
                               part: Int,
                               noteID: NoteID?,
                               rules: FermataRules?) {
        if !fermataTimes.contains(time) {
            fermataTimes.append(time)
            fermataTimes.sort()
        }

        let execution = fermata.execution

        guard execution?.isPlayed ?? true
        else { return }

        let end = time + span
        let extra: (units: Number, seconds: Number)

        switch execution?.hold {
        case let .added(length):
            let units = TimeType.number(of: length.duration)

            extra = (units, clock.seconds(end, end + units))

        case let .seconds(seconds):
            extra = (clock.length(seconds.duration.numberValue, end), seconds.duration.numberValue)

        case let .stretch(stretch):
            extra = _stretch(stretch, from: time, span: span)

        case nil:
            switch rules?.holds[fermata.shape] {
            case let .seconds(seconds):
                extra = (clock.length(seconds.duration.numberValue, end), seconds.duration.numberValue)

            case let .stretch(stretch):
                extra = _stretch(stretch, from: time, span: span)

            case nil:
                extra = _stretch(RenderingDefaults.fermataStretches[fermata.shape] ?? FermataStretch(numberValue: 2).unsafelyUnwrapped,
                                 from: time,
                                 span: span)
            }
        }

        holds.append(TimelineHold(extra: extra.units,
                                  extraSeconds: extra.seconds,
                                  isExplicit: execution?.hold != nil,
                                  noteID: noteID,
                                  part: part,
                                  span: span,
                                  time: time))

        switch execution?.pauseAfter {
        case let .added(length):
            let units = TimeType.number(of: length.duration)

            pauses.append(TimelinePause(length: units,
                                        seconds: clock.seconds(end, end + units),
                                        time: end))

        case let .seconds(seconds):
            _addPause(seconds.duration.numberValue, at: end)

        case nil:
            if let seconds = rules?.pauseAfter {
                _addPause(seconds.duration.numberValue, at: end)
            }
        }
    }

    private mutating func _addCaesura(_ execution: CaesuraExecution<TimeType>?,
                                      at time: Number,
                                      rules: InterpretationRules) {
        switch execution?.pause {
        case let .added(length):
            let units = TimeType.number(of: length.duration)

            pauses.append(TimelinePause(length: units,
                                        seconds: clock.seconds(time, time + units),
                                        time: time))

        case let .seconds(seconds):
            _addPause(seconds.duration.numberValue, at: time)

        case nil:
            _addPause((rules.caesura ?? RenderingDefaults.caesuraPause).duration.numberValue, at: time)
        }
    }

    private mutating func _addPause(_ seconds: Number,
                                    at time: Number) {
        pauses.append(TimelinePause(length: clock.length(seconds, time),
                                    seconds: seconds,
                                    time: time))
    }

    private func _stretch(_ stretch: FermataStretch,
                          from time: Number,
                          span: Number) -> (units: Number, seconds: Number) {
        let factor = stretch.numberValue - 1

        return (factor * span, factor * clock.seconds(time, time + span))
    }
}
