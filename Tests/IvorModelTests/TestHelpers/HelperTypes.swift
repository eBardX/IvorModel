// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
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

//
// Where a grid case’s time should fall: its bar, beat, offset and beat length.
//
struct ExpectedPosition {
    let bar: Int
    let beat: Int?
    let offset: Number
    let beatLength: Number?

    init(_ bar: Int,
         _ beat: Int?,
         _ offset: Number,
         _ beatLength: Number?) {
        self.bar = bar
        self.beat = beat
        self.offset = offset
        self.beatLength = beatLength
    }
}

struct GridCase {
    let entries: [(Number, String)]
    let pickup: Number
    let time: Number
    let expected: ExpectedPosition?
}

struct GridTable {
    let entries: [(Number, String)]
    let pickup: Number
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

struct PulseCase {
    let plain: String
    let pulse: [Number]
    let barLength: Number?
}

struct ScalingCase {
    let plain: String
    let factor: Number
    let expected: String
}

struct TypeNameVisitor: Template.ContentVisitor {
    func visit<TimeType, PitchType>(_ model: Template.Model<TimeType, PitchType>) -> String where TimeType.DurationType: TemplateDuration {
        "\(TimeType.self) \(PitchType.self)"
    }
}

// MARK: - CustomTestStringConvertible

extension GridCase: CustomTestStringConvertible {
    var testDescription: String {
        "\(entries.map { "\($1)@\($0)" }.joined(separator: ", ")) pickup \(pickup) at \(time)"
    }
}

// MARK: - CustomTestStringConvertible

extension GridTable: CustomTestStringConvertible {
    var testDescription: String {
        "\(entries.map { "\($1)@\($0)" }.joined(separator: ", ")) pickup \(pickup)"
    }
}

// MARK: - CustomTestStringConvertible

extension PulseCase: CustomTestStringConvertible {
    var testDescription: String {
        plain
    }
}

// MARK: - CustomTestStringConvertible

extension ScalingCase: CustomTestStringConvertible {
    var testDescription: String {
        "\(plain) × \(factor)"
    }
}

// MARK: - Equatable

extension NoteTripleSB: Equatable {
}

// MARK: - Sendable

extension ExpectedPosition: Sendable {
}

// MARK: - Sendable

extension GridCase: Sendable {
}

// MARK: - Sendable

extension GridTable: Sendable {
}

// MARK: - Sendable

extension PulseCase: Sendable {
}

// MARK: - Sendable

extension ScalingCase: Sendable {
}
