// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct PartErrorTests {
}

// MARK: -

extension PartErrorTests {
    private typealias PartSB = Part<BeatTime, Pitch>

    @Test
    func category() {
        #expect(PartSB.Error.noteTableFailure(.invalidAnchor).category != nil)
    }

    @Test
    func message_dynamicMapFailure() {
        let msg = PartSB.Error.dynamicMapFailure(.invalidAnchor).message

        #expect(msg.contains("Dynamic map"))
        #expect(msg.contains("anchor"))
    }

    @Test
    func message_instrumentMapFailure() {
        let msg = PartSB.Error.instrumentMapFailure(.invalidAnchor).message

        #expect(msg.contains("Instrument map"))
        #expect(msg.contains("anchor"))
    }

    @Test
    func message_noteTableFailure() {
        let msg = PartSB.Error.noteTableFailure(.invalidAnchor).message

        #expect(msg.contains("Note table"))
        #expect(msg.contains("anchor"))
    }

    @Test
    func message_panMapFailure() {
        let msg = PartSB.Error.panMapFailure(.invalidAnchor).message

        #expect(msg.contains("Pan map"))
        #expect(msg.contains("anchor"))
    }
}
