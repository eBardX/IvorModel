// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

private import XestiNumbers

extension Template {

    // MARK: Internal Nested Types

    //
    // Turns a source's note events into states, as a recipe chooses, one event after another — so
    // that it remembers the previous bass and duration that relative features are measured from.
    // A rest leaves the previous bass as it was.
    //
    internal struct StateBuilder<TimeType: TimeProtocol, PitchType: TemplatePitch> where TimeType.DurationType: TemplateDuration {

        // MARK: Internal Initializers

        internal init(recipe: AnalysisOptions.StateRecipe) {
            self.recipe = recipe
        }

        // MARK: Private Type Aliases

        private typealias PitchValue = State<TimeType, PitchType>.PitchValue
        private typealias TiedPitch  = NoteEvent<TimeType, PitchType>.TiedPitch

        // MARK: Private Instance Properties

        private let recipe: AnalysisOptions.StateRecipe

        private var previousBass: PitchType?
        private var previousDuration: TimeType.DurationType?
    }
}

// MARK: -

extension Template.StateBuilder {

    // MARK: Internal Instance Methods

    internal mutating func state(for noteEvent: NoteEvent<TimeType, PitchType>) -> Template.State<TimeType, PitchType> {
        let isRest = noteEvent.tiedPitches.isEmpty

        return Template.State(isRest: isRest,
                              duration: _durationValue(of: noteEvent.duration),
                              pitches: isRest ? nil : _pitchValue(of: noteEvent.tiedPitches))
    }

    // MARK: Private Instance Methods

    private mutating func _durationValue(of duration: TimeType.DurationType) -> Template.State<TimeType, PitchType>.DurationValue? {
        defer { previousDuration = duration }

        return switch recipe.duration {
        case .absolute:
            .absolute(duration)

        case .omitted:
            nil

        case .relative:
            .relative(duration.templateRatio(to: previousDuration ?? duration) ?? 1)
        }
    }

    //
    // The bass is the lowest pitch; the shape is every pitch's interval above it, lowest first.
    // A pitch whose interval can't be determined is left out.
    //
    private mutating func _intervalValue(of tiedPitches: [TiedPitch]) -> PitchValue? {
        guard let bass = tiedPitches.map(\.pitch).min()
        else { return nil }

        defer { previousBass = bass }

        guard let bassInterval = (previousBass ?? bass).templateInterval(to: bass) ?? bass.templateInterval(to: bass)
        else { return nil }

        let shape = tiedPitches.compactMap { tiedPitch in
            bass.templateInterval(to: tiedPitch.pitch).map {
                Template.Tone(value: $0,
                              startsTie: tiedPitch.startsTie,
                              endsTie: tiedPitch.endsTie)
            }
        }

        return .interval(bass: bassInterval,
                         shape: shape.sorted())
    }

    private mutating func _pitchValue(of tiedPitches: [TiedPitch]) -> PitchValue? {
        switch recipe.pitch {
        case .absolute:
            .absolute(tiedPitches.map {
                Template.Tone(value: $0.pitch,
                              startsTie: $0.startsTie,
                              endsTie: $0.endsTie)
            })

        case .interval:
            _intervalValue(of: tiedPitches)

        case .omitted:
            nil

        case .pitchClass:
            .pitchClass(Self._pitchClassTones(of: tiedPitches))
        }
    }

    // MARK: Private Type Methods

    //
    // Lowest first, each class once: an octave doubling keeps the lower pitch's ties.
    //
    private static func _pitchClassTones(of tiedPitches: [TiedPitch]) -> [Template.Tone<PitchType.PitchClassType>] {
        var seen: Set<PitchType.PitchClassType> = []

        return tiedPitches.sorted { $0.pitch < $1.pitch }.compactMap { tiedPitch in
            let pitchClass = tiedPitch.pitch.pitchClass

            guard seen.insert(pitchClass).inserted
            else { return nil }

            return Template.Tone(value: pitchClass,
                                 startsTie: tiedPitch.startsTie,
                                 endsTie: tiedPitch.endsTie)
        }
    }
}
