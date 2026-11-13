// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct MeterTests {
}

// MARK: -

extension MeterTests {
    @Test
    func codable_rejectsInvalidPlainString() {
        let data = Data(#"["3/0"]"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([Meter].self, from: data)
        }
    }

    @Test
    func codable_roundTripsAsPlainString() throws {
        let meters = [meter("2+2+3/8"), meter("6/8"), Meter.free]
        let data = try JSONEncoder().encode(meters)

        #expect(String(data: data, encoding: .utf8) == #"["2+2+3\/8","6\/8","free"]"#)
        #expect(try JSONDecoder().decode([Meter].self, from: data) == meters)
    }

    @Test
    func evenPulse() {
        #expect(meter("6/8").evenPulse == beats(frac(3, 8)))
        #expect(meter("2+2/8").evenPulse == beats(frac(1, 4)))
        #expect(meter("3+2/8").evenPulse == nil)
        #expect(Meter.free.evenPulse == nil)
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
    func init_rejectsInvalidParts() {
        #expect(Meter(numerators: [], denominator: 4) == nil)
        #expect(Meter(numerators: [3, 0], denominator: 4) == nil)
        #expect(Meter(numerators: [3], denominator: 0) == nil)
        #expect(Meter(numerators: [2, 2, 3], denominator: 8) == meter("2+2+3/8"))
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

    @Test(arguments: ["3/4", "2+2+3/8", "free", "4/3", "7/12", "12/8"])
    func plain_roundTrips(_ plain: String) throws {
        let meter = try #require(Meter(plain: plain))

        #expect(meter.plain == plain)
        #expect(meter.description == plain)
    }

    @Test(arguments: Fixtures.pulseCases)
    func pulseRule(_ testCase: PulseCase) throws {
        let meter = try #require(Meter(plain: testCase.plain))

        #expect(meter.pulse.map(\.numberValue) == testCase.pulse)
        #expect(meter.barLength?.numberValue == testCase.barLength)
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

    @Test(arguments: Fixtures.scalingCases)
    func scalingRule(_ testCase: ScalingCase) {
        let scaled = meter(testCase.plain).scaled(by: testCase.factor)

        #expect(scaled.plain == testCase.expected)
        #expect(scaled.barLength?.numberValue == meter(testCase.plain).barLength.map { $0.numberValue * testCase.factor })
    }
}
