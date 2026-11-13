// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct WorkContentTests {
}

// MARK: -

extension WorkContentTests {
    @Test
    func codable_beat() throws {
        let original: Work.Content = .standardBeat([Part<BeatTime, Pitch>(name: "Piano")],
                                                   TempoMap(),
                                                   MeterTable())
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Work.Content.self,
                                               from: data)

        #expect(decoded.pitchNotation == original.pitchNotation)
        #expect(decoded.timeBasis == original.timeBasis)
    }

    @Test
    func codable_wall() throws {
        let original: Work.Content = .standardWall([Part<WallTime, Pitch>(name: "Piano")])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Work.Content.self,
                                               from: data)

        #expect(decoded.pitchNotation == original.pitchNotation)
        #expect(decoded.timeBasis == original.timeBasis)
    }

    @Test
    func content_codable_roundTripsNonEmptyTable() throws {
        let meterTable = try makeMeterTable([(0, "3/4"), (frac(7, 4), "2+2+3/8")],
                                            pickup: frac(1, 4))
        let content = Work.Content.standardBeat([], TempoMap(), meterTable)
        let data = try JSONEncoder().encode(content)
        let decoded = try JSONDecoder().decode(Work.Content.self, from: data)

        guard case let .standardBeat(_, _, decodedTable) = decoded
        else { Issue.record("not standard beat"); return }

        #expect(decodedTable == meterTable)
        #expect(decodedTable.pickup == beats(frac(1, 4)))
    }

    @Test
    func content_decode_withoutMeterTable_fails() throws {
        let content = try Work.Content.keyboardBeat([], TempoMap(), makeMeterTable([(0, "6/8")]))
        let data = try JSONEncoder().encode(content)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object.removeValue(forKey: "meterTable") != nil)

        let stripped = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Work.Content.self, from: stripped)
        }
    }

    @Test
    func content_empty_beat_hasEmptyMeterTable() {
        for pitchNotation in [PitchNotation.absolute, .keyboard, .standard] {
            let work = Work(content: .empty(timeBasis: .beat, pitchNotation: pitchNotation))

            #expect(work.meterTable == MeterTable())
        }
    }

    @Test(arguments: [TimeBasis.beat, .wall],
          [PitchNotation.absolute, .keyboard, .standard])
    func empty(timeBasis: TimeBasis,
               pitchNotation: PitchNotation) {
        let work = Work(content: .empty(timeBasis: timeBasis,
                                        pitchNotation: pitchNotation))

        #expect(work.timeBasis == timeBasis)
        #expect(work.pitchNotation == pitchNotation)
        #expect(work.partCount == 0)
        #expect((work.tempoMap != nil) == (timeBasis == .beat))
    }

    @Test
    func pitchNotation_absolute() {
        let content: Work.Content = .absoluteWall([])

        #expect(content.pitchNotation == .absolute)
    }

    @Test
    func pitchNotation_keyboard() {
        let content: Work.Content = .keyboardWall([])

        #expect(content.pitchNotation == .keyboard)
    }

    @Test
    func pitchNotation_standard() {
        let content: Work.Content = .standardWall([])

        #expect(content.pitchNotation == .standard)
    }

    @Test
    func timeBasis_beat() {
        let content: Work.Content = .standardBeat([], TempoMap(), MeterTable())

        #expect(content.timeBasis == .beat)
    }

    @Test
    func timeBasis_wall() {
        let content: Work.Content = .standardWall([])

        #expect(content.timeBasis == .wall)
    }
}
