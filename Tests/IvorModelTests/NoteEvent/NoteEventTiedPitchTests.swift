// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing

struct NoteEventTiedPitchTests {
}

// MARK: -

extension NoteEventTiedPitchTests {
    typealias TiedPitchSB = NoteEvent<BeatTime, Pitch>.TiedPitch

    @Test
    func beginsTie_neither() {
        let tp = TiedPitchSB(pitch: .a4)

        #expect(!tp.beginsTie)
    }

    @Test
    func beginsTie_start() {
        let tp = TiedPitchSB(pitch: .a4, beginsTie: true)

        #expect(tp.beginsTie)
    }

    @Test
    func beginsTie_stop() {
        let tp = TiedPitchSB(pitch: .a4, endsTie: true)

        #expect(!tp.beginsTie)
    }

    @Test
    func beginsTie_stopStart() {
        let tp = TiedPitchSB(pitch: .a4, beginsTie: true, endsTie: true)

        #expect(tp.beginsTie)
    }

    @Test
    func codable() throws {
        for original: TiedPitchSB in [.neither(.a4), .start(.a4), .stop(.a4), .stopStart(.a4)] {
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(TiedPitchSB.self, from: data)

            #expect(decoded == original)
        }
    }

    @Test
    func comparable_differentPitch() {
        let tp1 = TiedPitchSB.neither(.a4)
        let tp2 = TiedPitchSB.neither(.cSharp5)

        #expect(tp1 < tp2)
        #expect(!(tp2 < tp1))
    }

    @Test
    func comparable_samePitch() {
        let stopStart = TiedPitchSB.stopStart(.a4)
        let stop      = TiedPitchSB.stop(.a4)
        let start     = TiedPitchSB.start(.a4)
        let neither   = TiedPitchSB.neither(.a4)

        #expect(stopStart < stop)
        #expect(stop < start)
        #expect(start < neither)
    }

    @Test
    func endsTie_neither() {
        let tp = TiedPitchSB(pitch: .a4)

        #expect(!tp.endsTie)
    }

    @Test
    func endsTie_start() {
        let tp = TiedPitchSB(pitch: .a4, beginsTie: true)

        #expect(!tp.endsTie)
    }

    @Test
    func endsTie_stop() {
        let tp = TiedPitchSB(pitch: .a4, endsTie: true)

        #expect(tp.endsTie)
    }

    @Test
    func endsTie_stopStart() {
        let tp = TiedPitchSB(pitch: .a4, beginsTie: true, endsTie: true)

        #expect(tp.endsTie)
    }

    @Test
    func init_neither() {
        let tp = TiedPitchSB(pitch: .a4)

        #expect(tp == .neither(.a4))
    }

    @Test
    func init_start() {
        let tp = TiedPitchSB(pitch: .a4, beginsTie: true)

        #expect(tp == .start(.a4))
    }

    @Test
    func init_stop() {
        let tp = TiedPitchSB(pitch: .a4, endsTie: true)

        #expect(tp == .stop(.a4))
    }

    @Test
    func init_stopStart() {
        let tp = TiedPitchSB(pitch: .a4, beginsTie: true, endsTie: true)

        #expect(tp == .stopStart(.a4))
    }

    @Test
    func pitch() {
        #expect(TiedPitchSB.neither(.a4).pitch == .a4)
        #expect(TiedPitchSB.start(.a4).pitch == .a4)
        #expect(TiedPitchSB.stop(.a4).pitch == .a4)
        #expect(TiedPitchSB.stopStart(.a4).pitch == .a4)
    }
}
