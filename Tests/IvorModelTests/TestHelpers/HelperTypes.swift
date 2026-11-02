// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import XestiMarkov
import XestiTools

typealias StandardBeatOptions = Template.GenerationOptions<BeatTime, Pitch>

typealias StandardBeatState = Template.State<BeatTime, Pitch>

struct BeginCountVisitor: Template.ContentVisitor {
    let role: Template.ChainRole

    func visit<TimeType>(_ model: Template.Model<TimeType, some Any>) -> UInt? where TimeType.DurationType: TemplateDuration {
        guard let chain = model.chains.chain(for: role)
        else { return nil }

        var count: UInt = 0

        chain.forEach { transition in
            if case .begin = transition.source {
                count += transition.weight
            }
        }

        return count
    }
}

struct MaximumOrderVisitor: Template.ContentVisitor {
    func visit<TimeType>(_ model: Template.Model<TimeType, some Any>) -> Int where TimeType.DurationType: TemplateDuration {
        model.chains.maximumOrder
    }
}

//
// A note’s attack, duration and start pitch, compared by value (so 2 and 2.0
// are equal) and ignoring its note ID.
//
struct NoteTripleSB {
    let attack: BeatTime
    let duration: BeatDuration
    let pitch: Pitch
}

struct TypeNameVisitor: Template.ContentVisitor {
    func visit<TimeType, PitchType>(_ model: Template.Model<TimeType, PitchType>) -> String where TimeType.DurationType: TemplateDuration {
        "\(TimeType.self) \(PitchType.self)"
    }
}

// MARK: - Equatable

extension NoteTripleSB: Equatable {
}
