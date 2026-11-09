// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiNumbers

struct PedalLevelTests {
}

// MARK: -

extension PedalLevelTests {
    @Test
    func codable_roundTrip() throws {
        for level in [Pedal.Level.off, .on, pedalLevel(64, 127)] {
            let data = try JSONEncoder().encode(level)

            #expect(try JSONDecoder().decode(Pedal.Level.self, from: data) == level)
        }
    }

    @Test
    func comparable() {
        #expect(Pedal.Level.off < pedalLevel(1, 2))
        #expect(pedalLevel(1, 2) < Pedal.Level.on)
    }

    @Test
    func init_bounds() {
        #expect(Pedal.Level(numberValue: Number(numerator: -1, denominator: 100)) == nil)
        #expect(Pedal.Level(numberValue: 0) == .off)
        #expect(Pedal.Level(numberValue: 1) == .on)
        #expect(Pedal.Level(numberValue: Number(numerator: 101, denominator: 100)) == nil)
    }

    @Test
    func isDown() {
        #expect(!Pedal.Level.off.isDown)
        #expect(!pedalLevel(63, 127).isDown)
        #expect(pedalLevel(1, 2).isDown)
        #expect(pedalLevel(64, 127).isDown)
        #expect(Pedal.Level.on.isDown)
    }

    @Test
    func isValid() {
        #expect(Pedal.Level.isValid(0))
        #expect(Pedal.Level.isValid(1))
        #expect(!Pedal.Level.isValid(-1))
        #expect(!Pedal.Level.isValid(2))
    }

    @Test
    func offAndOn() {
        #expect(Pedal.Level.off.numberValue == 0)
        #expect(Pedal.Level.on.numberValue == 1)
    }

    @Test
    func plain() {
        #expect(Pedal.Level.off.plain == "off")
        #expect(Pedal.Level.on.plain == "on")
        #expect(pedalLevel(64, 127).plain == "64/127")
        #expect(pedalLevel(1, 2).plain == "1/2")
    }

    @Test
    func plain_roundTrip() {
        for value in [Pedal.Level.off, .on, pedalLevel(64, 127), pedalLevel(1, 2)] {
            #expect(Pedal.Level(plain: value.plain) == value)
        }

        #expect(Pedal.Level(plain: "0") == .off)
        #expect(Pedal.Level(plain: "1") == .on)
        #expect(Pedal.Level(plain: "0.5") == pedalLevel(1, 2))
        #expect(Pedal.Level(plain: "-1") == nil)
        #expect(Pedal.Level(plain: "2") == nil)
        #expect(Pedal.Level(plain: "") == nil)
        #expect(Pedal.Level(plain: "down") == nil)
    }
}
