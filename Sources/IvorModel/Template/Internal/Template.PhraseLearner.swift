// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming

private import Foundation
private import XestiNumbers

extension Template {

    // MARK: Internal Nested Types

    //
    // Turns a phrase to continue into what the template's chains learned: its note events with
    // the template's duration and pitch tolerances, and their states under its state recipe.
    //
    // A template doesn't keep the function that grouped its durations, only each representative's
    // members.  So a duration that is a member goes to its representative; one that isn't goes
    // where the tolerance would put it — a step's rounding, or, for a proportional band, the
    // nearest representative within the band — or else stays as it is.
    //
    internal struct PhraseLearner<TimeType: TimeProtocol, PitchType: TemplatePitch> where TimeType.DurationType: TemplateDuration {

        // MARK: Internal Initializers

        internal init(analysisOptions: AnalysisOptions,
                      vocabulary: Vocabulary<TimeType, PitchType>,
                      grouping: @escaping ([DurationType]) -> [DurationType: DurationType],
                      rounding: @escaping (PitchType) -> PitchType) {
            self.analysisOptions = analysisOptions
            self.grouping = grouping
            self.rounding = rounding
            self.vocabulary = vocabulary
        }

        // MARK: Internal Instance Properties

        internal let analysisOptions: AnalysisOptions

        // MARK: Internal Type Aliases

        internal typealias DurationType = TimeType.DurationType

        // MARK: Private Instance Properties

        private let grouping: ([DurationType]) -> [DurationType: DurationType]
        private let rounding: (PitchType) -> PitchType
        private let vocabulary: Vocabulary<TimeType, PitchType>
    }
}

// MARK: -

extension Template.PhraseLearner {

    // MARK: Internal Instance Methods

    //
    // The phrase's note events with the template's tolerances, and their states.
    //
    internal func learn(_ noteEvents: [NoteEvent<TimeType, PitchType>]) -> (noteEvents: [NoteEvent<TimeType, PitchType>],
                                                                            states: [Template.State<TimeType, PitchType>]) {
        let tolerated = noteEvents.map {
            NoteEvent<TimeType, PitchType>(tiedPitches: Template.roundedPitches($0.tiedPitches,
                                                                                with: rounding),
                                           duration: _representative(of: $0.duration))
        }

        var builder = Template.StateBuilder<TimeType, PitchType>(recipe: analysisOptions.states)

        return (tolerated, tolerated.map { builder.state(for: $0) })
    }

    // MARK: Private Instance Methods

    private func _representative(of duration: DurationType) -> DurationType {
        if let member = vocabulary.durationMembers.first(where: { $0.value[duration] != nil }) {
            return member.key
        }

        guard let tolerance = analysisOptions.durations
        else { return duration }

        let grouped = grouping([duration])[duration] ?? duration

        guard case let .proportional(fraction) = tolerance,
              vocabulary.durations[grouped] == nil
        else { return grouped }

        let band = log(1 + fraction)
        let nearest = vocabulary.durations.keys.compactMap { representative -> (spread: Double, duration: DurationType)? in
            guard let ratio = representative.templateRatio(to: duration)?.doubleValue,
                  ratio > 0
            else { return nil }

            let spread = abs(log(ratio))

            return spread <= band ? (spread, representative) : nil
        }

        return nearest.min { ($0.spread, $0.duration) < ($1.spread, $1.duration) }?.duration ?? duration
    }
}
