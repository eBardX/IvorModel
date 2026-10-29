// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import Synchronization
internal import XestiMarkov

extension Template {

    // MARK: Internal Nested Types

    //
    // Turns generated states back into note events, one after another, from anchors that start at
    // the recipe's start pitch and duration (or the source's first event) and follow what has been
    // realized since: the previous bass for intervals, the previous pitch for pitch classes, and
    // the previous duration for ratios.
    //
    // Generation asks it twice about each step: `allows(_:)`, from the generator stack's filter,
    // while choosing among the candidates; then `advance(with:)`, from `generate(until:)`, for the
    // chosen state.  XestiMarkov makes those calls in that order, on one thread, so the anchors are
    // always the previous step's.  They're behind a `Mutex` only because the filter must be
    // `Sendable`.
    //
    // When `range` is set (for relative recipes: the constraints' range, or else the source's,
    // moved to the start pitch), `allows(_:)` rejects states that would leave it,
    // and `advance(with:)` brings back any that do — those the fallback generator chooses when
    // nothing else was allowed: an interval is reflected, and then, like a pitch class, moved by
    // octaves until its bass is in range.
    //
    // With `samplesMembers`, an absolute pitch or duration that a tolerance grouped is replaced, in
    // the output only, by one of its members, drawn by count.
    //
    internal final class Realizer<TimeType: TimeProtocol, PitchType: TemplatePitch>: Sendable where TimeType.DurationType: TemplateDuration {

        // MARK: Internal Initializers

        internal init(vocabulary: Vocabulary<TimeType, PitchType>,
                      options: GenerationOptions<TimeType, PitchType>,
                      isRelative: Bool,
                      memberSeed: UInt64) {
            let startDuration = options.startDuration ?? vocabulary.first?.duration ?? vocabulary.commonestDuration
            let firstBass = vocabulary.first?.tiedPitches.map(\.pitch).min()
            let startPitch = options.startPitch ?? firstBass ?? vocabulary.commonestPitch

            self.anchors = Mutex(_Anchors(bass: startPitch,
                                          duration: startDuration,
                                          pitch: startPitch,
                                          rng: SeededRandomNumberGenerator(seed: memberSeed)))
            self.constraints = options.constraints
            self.defaultDuration = options.startDuration ?? vocabulary.commonestDuration
            self.defaultPitch = options.startPitch ?? vocabulary.commonestPitch
            self.range = isRelative ? options.constraints.pitchRange ?? Self._sourceRange(of: vocabulary,
                                                                                          movedFrom: firstBass,
                                                                                          to: options.startPitch) : nil
            self.samplesMembers = options.samplesMembers
            self.vocabulary = vocabulary
        }

        // MARK: Internal Instance Properties

        internal let range: ClosedRange<PitchType>?

        // MARK: Private Type Aliases

        private typealias DurationType = TimeType.DurationType
        private typealias Event        = NoteEvent<TimeType, PitchType>
        private typealias TiedPitch    = Event.TiedPitch

        // MARK: Private Nested Types

        private struct _Anchors {
            var bass: PitchType?
            var duration: DurationType?
            var pitch: PitchType?
            var rng: SeededRandomNumberGenerator
        }

        // MARK: Private Instance Properties

        private let anchors: Mutex<_Anchors>
        private let constraints: GenerationOptions<TimeType, PitchType>.Constraints
        private let defaultDuration: DurationType?
        private let defaultPitch: PitchType?
        private let samplesMembers: Bool
        private let vocabulary: Vocabulary<TimeType, PitchType>
    }
}

// MARK: -

extension Template.Realizer {

    // MARK: Internal Instance Methods

    //
    // Realizes `state` and adopts the result as the anchors for the next state — or returns `nil`,
    // leaving the anchors alone, if it can't be realized.
    //
    internal func advance(with state: Template.State<TimeType, PitchType>) -> NoteEvent<TimeType, PitchType>? {
        anchors.withLock { anchors in
            guard let event = _realize(state,
                                       from: anchors,
                                       bringingIntoRange: true)
            else { return nil }

            let bass = event.tiedPitches.map(\.pitch).min()

            anchors.bass = bass ?? anchors.bass
            anchors.duration = event.duration
            anchors.pitch = bass ?? anchors.pitch

            return samplesMembers ? _sampled(event,
                                             for: state,
                                             using: &anchors.rng) : event
        }
    }

    //
    // Whether `state`, realized from the current anchors, stays in `range` (when checked) and meets
    // the constraints.
    //
    internal func allows(_ state: Template.State<TimeType, PitchType>,
                         checkingRange: Bool) -> Bool {
        anchors.withLock { anchors in
            guard let event = _realize(state,
                                       from: anchors,
                                       bringingIntoRange: false)
            else { return false }

            if checkingRange,
               let range,
               !event.tiedPitches.allSatisfy({ range.contains($0.pitch) }) {
                return false
            }

            return constraints.allows(event)
        }
    }

    // MARK: Private Instance Methods

    private func _intervalPitches(bass bassInterval: DirectedInterval<PitchType.IntervalType>,
                                  shape: [Template.Tone<DirectedInterval<PitchType.IntervalType>>],
                                  from anchors: _Anchors,
                                  bringingIntoRange: Bool) -> [TiedPitch]? {
        guard let previousBass = anchors.bass,
              var bass = previousBass.transposed(by: bassInterval)
        else { return nil }

        if bringingIntoRange,
           let range,
           !range.contains(bass) {
            let reflected: PitchType? = switch bassInterval.direction {
            case .ascending:
                previousBass.transposed(by: DirectedInterval(interval: bassInterval.interval,
                                                             direction: .descending))

            case .descending:
                previousBass.transposed(by: DirectedInterval(interval: bassInterval.interval,
                                                             direction: .ascending))

            case .same:
                nil
            }

            if let reflected,
               range.contains(reflected) {
                bass = reflected
            } else if let moved = _movedIntoRange(bass) {
                bass = moved
            }
        }

        return shape.compactMap { tone in
            bass.transposed(by: tone.value).map {
                TiedPitch(pitch: $0,
                          startsTie: tone.startsTie,
                          endsTie: tone.endsTie)
            }
        }
    }

    //
    // The pitch moved by the fewest octaves that bring it into `range`, or `nil` if none do.
    //
    private func _movedIntoRange(_ pitch: PitchType) -> PitchType? {
        guard let range
        else { return pitch }

        for octaves in 1...10 {
            for candidate in [pitch.shifted(octaves: octaves), pitch.shifted(octaves: -octaves)] {
                if let candidate, range.contains(candidate) {
                    return candidate
                }
            }
        }

        return nil
    }

    //
    // The lowest class nearest the previous pitch; each further class at the nearest pitch above
    // the one before, so a chord comes out in close position.  Brought into range as a whole.
    //
    private func _pitchClassPitches(_ tones: [Template.Tone<PitchType.PitchClassType>],
                                    from anchors: _Anchors,
                                    bringingIntoRange: Bool) -> [TiedPitch]? {
        guard var previous = anchors.pitch
        else { return nil }

        var pitches: [PitchType] = []

        for tone in tones {
            guard var pitch = previous.nearest(tone.value)
            else { return nil }

            if !pitches.isEmpty, pitch <= previous {
                guard let higher = pitch.shifted(octaves: 1)
                else { return nil }

                pitch = higher
            }

            pitches.append(pitch)
            previous = pitch
        }

        if bringingIntoRange,
           let range,
           let bass = pitches.first,
           !range.contains(bass),
           let moved = _movedIntoRange(bass),
           let octaves = _octaves(from: bass, to: moved) {
            pitches = pitches.compactMap { $0.shifted(octaves: octaves) }
        }

        return zip(tones, pitches).map { tone, pitch in
            TiedPitch(pitch: pitch,
                      startsTie: tone.startsTie,
                      endsTie: tone.endsTie)
        }
    }

    private func _octaves(from pitch: PitchType,
                          to other: PitchType) -> Int? {
        (-10...10).first { pitch.shifted(octaves: $0) == other }
    }

    private func _realize(_ state: Template.State<TimeType, PitchType>,
                          from anchors: _Anchors,
                          bringingIntoRange: Bool) -> NoteEvent<TimeType, PitchType>? {
        let duration: DurationType? = switch state.duration {
        case let .absolute(duration):
            duration

        case let .relative(ratio):
            anchors.duration?.multiplied(by: ratio)

        case nil:
            defaultDuration
        }

        guard let duration,
              !duration.isZero
        else { return nil }

        if state.isRest {
            return NoteEvent(tiedPitches: [],
                             duration: duration)
        }

        let tiedPitches: [TiedPitch]? = switch state.pitches {
        case let .absolute(tones):
            tones.map {
                TiedPitch(pitch: $0.value,
                          startsTie: $0.startsTie,
                          endsTie: $0.endsTie)
            }

        case let .interval(bass, shape):
            _intervalPitches(bass: bass,
                             shape: shape,
                             from: anchors,
                             bringingIntoRange: bringingIntoRange)

        case let .pitchClass(tones):
            _pitchClassPitches(tones,
                               from: anchors,
                               bringingIntoRange: bringingIntoRange)

        case nil:
            defaultPitch.map { [TiedPitch(pitch: $0)] }
        }

        guard let tiedPitches,
              !tiedPitches.isEmpty
        else { return nil }

        return NoteEvent(tiedPitches: tiedPitches,
                         duration: duration)
    }

    //
    // Only absolute values are replaced: relative ones aren't representatives of anything.
    //
    private func _sampled(_ event: NoteEvent<TimeType, PitchType>,
                          for state: Template.State<TimeType, PitchType>,
                          using rng: inout SeededRandomNumberGenerator) -> NoteEvent<TimeType, PitchType> {
        var duration = event.duration
        var tiedPitches = event.tiedPitches

        if case .absolute = state.duration,
           let members = vocabulary.durationMembers[duration] {
            duration = Self._draw(from: members,
                                  using: &rng) ?? duration
        }

        if case .absolute = state.pitches {
            tiedPitches = tiedPitches.map { tiedPitch in
                guard let members = vocabulary.pitchMembers[tiedPitch.pitch],
                      let pitch = Self._draw(from: members,
                                             using: &rng)
                else { return tiedPitch }

                return TiedPitch(pitch: pitch,
                                 startsTie: tiedPitch.startsTie,
                                 endsTie: tiedPitch.endsTie)
            }
        }

        return NoteEvent(tiedPitches: tiedPitches,
                         duration: duration)
    }

    // MARK: Private Type Methods

    //
    // The source's range — moved by the interval from the source's first bass to the start pitch,
    // when one is given, so that a template started elsewhere keeps the same span around it.
    //
    private static func _sourceRange(of vocabulary: Template.Vocabulary<TimeType, PitchType>,
                                     movedFrom firstBass: PitchType?,
                                     to startPitch: PitchType?) -> ClosedRange<PitchType>? {
        guard let range = vocabulary.pitchRange
        else { return nil }

        guard let firstBass,
              let startPitch,
              let interval = firstBass.templateInterval(to: startPitch),
              let lowest = range.lowerBound.transposed(by: interval),
              let highest = range.upperBound.transposed(by: interval),
              lowest <= highest
        else { return range }

        return lowest...highest
    }

    //
    // A member drawn in proportion to its count, from the members in sorted order, so that a seed
    // always draws the same one.
    //
    private static func _draw<Value: Comparable>(from members: [Value: Int],
                                                 using rng: inout SeededRandomNumberGenerator) -> Value? {
        let total = members.values.reduce(0, +)

        guard total > 0
        else { return nil }

        var remaining = Int(rng.next() % UInt64(total))

        for value in members.keys.sorted() {
            remaining -= members[value, default: 0]

            if remaining < 0 {
                return value
            }
        }

        return nil
    }
}
