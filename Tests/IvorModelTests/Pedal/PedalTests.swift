// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct PedalTests {
}

// MARK: -

extension PedalTests {
    @Test
    func allCases_order() {
        #expect(Pedal.allCases == [.sustain, .sostenuto, .soft, .legato, .portamento])
    }

    @Test
    func codable_asDictionaryKey() throws {
        let original: [Pedal: Int] = [.soft: 2, .sustain: 1]
        let data = try JSONEncoder().encode(original)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Int]

        #expect(object == ["soft": 2, "sustain": 1])
        #expect(try JSONDecoder().decode([Pedal: Int].self, from: data) == original)
    }

    @Test
    func codable_roundTrip() throws {
        for pedal in Pedal.allCases {
            let data = try JSONEncoder().encode(pedal)

            #expect(try JSONDecoder().decode(Pedal.self, from: data) == pedal)
        }
    }

    @Test
    func rawValues() {
        #expect(Pedal.sustain.rawValue == "sustain")
        #expect(Pedal.sostenuto.rawValue == "sostenuto")
        #expect(Pedal.soft.rawValue == "soft")
        #expect(Pedal.legato.rawValue == "legato")
        #expect(Pedal.portamento.rawValue == "portamento")
    }
}
