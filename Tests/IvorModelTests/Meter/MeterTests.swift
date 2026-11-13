// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct MeterTests {
}

// MARK: - Pulse rule (METER_TABLE.md 1.10)

extension MeterTests {
    struct PulseCase: CustomTestStringConvertible, Sendable {
        let plain: String
        let pulse: [Number]
        let barLength: Number?

        var testDescription: String {
            plain
        }
    }

    static let pulseCases: [PulseCase] = [PulseCase(plain: "4/4", pulse: Array(repeating: frac(1, 4), count: 4), barLength: 1),
                                          PulseCase(plain: "3/4", pulse: Array(repeating: frac(1, 4), count: 3), barLength: frac(3, 4)),
                                          PulseCase(plain: "2/2", pulse: Array(repeating: frac(1, 2), count: 2), barLength: 1),
                                          PulseCase(plain: "3/2", pulse: Array(repeating: frac(1, 2), count: 3), barLength: frac(3, 2)),
                                          PulseCase(plain: "6/8", pulse: Array(repeating: frac(3, 8), count: 2), barLength: frac(3, 4)),
                                          PulseCase(plain: "9/8", pulse: Array(repeating: frac(3, 8), count: 3), barLength: frac(9, 8)),
                                          PulseCase(plain: "12/8", pulse: Array(repeating: frac(3, 8), count: 4), barLength: frac(3, 2)),
                                          PulseCase(plain: "3/8", pulse: [frac(3, 8)], barLength: frac(3, 8)),
                                          PulseCase(plain: "3/16", pulse: [frac(3, 16)], barLength: frac(3, 16)),
                                          PulseCase(plain: "5/8", pulse: Array(repeating: frac(1, 8), count: 5), barLength: frac(5, 8)),
                                          PulseCase(plain: "6/4", pulse: Array(repeating: frac(3, 4), count: 2), barLength: frac(3, 2)),
                                          PulseCase(plain: "9/16", pulse: Array(repeating: frac(3, 16), count: 3), barLength: frac(9, 16)),
                                          PulseCase(plain: "6/12", pulse: Array(repeating: frac(1, 4), count: 2), barLength: frac(1, 2)),
                                          PulseCase(plain: "3/12", pulse: [frac(1, 4)], barLength: frac(1, 4)),
                                          PulseCase(plain: "4/3", pulse: Array(repeating: frac(1, 3), count: 4), barLength: frac(4, 3)),
                                          PulseCase(plain: "7/12", pulse: Array(repeating: frac(1, 12), count: 7), barLength: frac(7, 12)),
                                          PulseCase(plain: "2+2+3/8", pulse: [frac(1, 4), frac(1, 4), frac(3, 8)], barLength: frac(7, 8)),
                                          PulseCase(plain: "3+2/8", pulse: [frac(3, 8), frac(1, 4)], barLength: frac(5, 8)),
                                          PulseCase(plain: "free", pulse: [], barLength: nil)]

    @Test(arguments: pulseCases)
    func pulseRule(_ testCase: PulseCase) throws {
        let meter = try #require(Meter(plain: testCase.plain))

        #expect(meter.pulse.map(\.numberValue) == testCase.pulse)
        #expect(meter.barLength?.numberValue == testCase.barLength)
    }

    @Test
    func evenPulse() {
        #expect(meter("6/8").evenPulse == beats(frac(3, 8)))
        #expect(meter("2+2/8").evenPulse == beats(frac(1, 4)))
        #expect(meter("3+2/8").evenPulse == nil)
        #expect(Meter.free.evenPulse == nil)
    }
}

// MARK: - Scaling rule (METER_TABLE.md 1.10)

extension MeterTests {
    struct ScalingCase: CustomTestStringConvertible, Sendable {
        let plain: String
        let factor: Number
        let expected: String

        var testDescription: String {
            "\(plain) × \(factor)"
        }
    }

    static let scalingCases: [ScalingCase] = [("3/4", ["3/2", "9/8", "3/3", "3/8", "3/12"]),
                                              ("6/8", ["6/4", "18/16", "6/6", "6/16", "6/24"]),
                                              ("2+2+3/8", ["2+2+3/4", "6+6+9/16", "2+2+3/6", "2+2+3/16", "2+2+3/24"])].flatMap { plain, expected in
        zip([2, frac(3, 2), frac(4, 3), frac(1, 2), frac(1, 3)], expected).map {
            ScalingCase(plain: plain, factor: $0, expected: $1)
        }
    }

    @Test(arguments: scalingCases)
    func scalingRule(_ testCase: ScalingCase) {
        let scaled = meter(testCase.plain).scaled(by: testCase.factor)

        #expect(scaled.plain == testCase.expected)
        #expect(scaled.barLength?.numberValue == meter(testCase.plain).barLength.map { $0.numberValue * testCase.factor })
    }

    @Test
    func scaled_changesPulse() {
        // 3/4 ÷ 2 is 3/8, felt in one.
        #expect(meter("3/4").scaled(by: frac(1, 2)).pulse == [beats(frac(3, 8))])
    }

    @Test
    func scaled_freeStaysFree() {
        #expect(Meter.free.scaled(by: 2) == .free)
    }
}

// MARK: - Plain form and Codable

extension MeterTests {
    @Test(arguments: ["3/4", "2+2+3/8", "free", "4/3", "7/12", "12/8"])
    func plain_roundTrips(_ plain: String) throws {
        let meter = try #require(Meter(plain: plain))

        #expect(meter.plain == plain)
        #expect(meter.description == plain)
    }

    @Test
    func plain_acceptsSpaces() {
        #expect(Meter(plain: " 2 + 2 + 3 / 8 ")?.plain == "2+2+3/8")
        #expect(Meter(plain: "3 /4")?.plain == "3/4")
    }

    @Test(arguments: ["0/4", "3/0", "+/8", "3/", "/4", "", "3+/8", "3/4/4", "a/4", "-3/4", "3.0/4", "Free", "3 4/4"])
    func plain_rejects(_ plain: String) {
        #expect(Meter(plain: plain) == nil)
    }

    @Test
    func init_rejectsInvalidParts() {
        #expect(Meter(numerators: [], denominator: 4) == nil)
        #expect(Meter(numerators: [3, 0], denominator: 4) == nil)
        #expect(Meter(numerators: [3], denominator: 0) == nil)
        #expect(Meter(numerators: [2, 2, 3], denominator: 8) == meter("2+2+3/8"))
    }

    @Test
    func free_properties() {
        #expect(Meter.free.isFree)
        #expect(Meter.free.numerators.isEmpty)
        #expect(Meter.free.denominator == nil)
        #expect(Meter.free.pulse.isEmpty)
        #expect(!meter("3/4").isFree)
        #expect(meter("3/4").numerators == [3])
        #expect(meter("3/4").denominator == 4)
    }

    @Test
    func codable_roundTripsAsPlainString() throws {
        let meters = [meter("2+2+3/8"), meter("6/8"), Meter.free]
        let data = try JSONEncoder().encode(meters)

        #expect(String(data: data, encoding: .utf8) == #"["2+2+3\/8","6\/8","free"]"#)
        #expect(try JSONDecoder().decode([Meter].self, from: data) == meters)
    }

    @Test
    func codable_rejectsInvalidPlainString() {
        let data = Data(#"["3/0"]"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([Meter].self, from: data)
        }
    }
}
