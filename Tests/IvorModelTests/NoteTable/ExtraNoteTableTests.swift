// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct ExtraNoteTableTests {
}

// MARK: -

extension ExtraNoteTableTests {
    private typealias NoteTableSB = NoteTable<BeatTime, Pitch>

    @Test
    func accent() {
        #expect(Extra.accent.name == "accent")
        #expect(Extra.accent.values.isEmpty)
    }

    @Test
    func articulation() {
        #expect(Extra.articulation.name == "articulation")
        #expect(Extra.articulation.values.isEmpty)
    }

    @Test
    func breathMark() {
        #expect(Extra.breathMark.name == "breathMark")
        #expect(Extra.breathMark.values.isEmpty)
    }

    @Test
    func downBow() {
        #expect(Extra.downBow.name == "downBow")
        #expect(Extra.downBow.values.isEmpty)
    }

    @Test
    func fermata() {
        #expect(Extra.fermata.name == "fermata")
        #expect(Extra.fermata.values.isEmpty)
    }

    @Test
    func fingering() {
        #expect(Extra.fingering.name == "fingering")
        #expect(Extra.fingering.values.isEmpty)
    }

    @Test
    func harmonic() {
        #expect(Extra.harmonic.name == "harmonic")
        #expect(Extra.harmonic.values.isEmpty)
    }

    @Test
    func marcato() {
        #expect(Extra.marcato.name == "marcato")
        #expect(Extra.marcato.values.isEmpty)
    }

    @Test
    func midiKeyPressure() {
        #expect(Extra.midiKeyPressure.name == "midiKeyPressure")
        #expect(Extra.midiKeyPressure.values.isEmpty)
    }

    @Test
    func mordent() {
        #expect(Extra.mordent.name == "mordent")
        #expect(Extra.mordent.values.isEmpty)
    }

    @Test
    func pizzicato() {
        #expect(Extra.pizzicato.name == "pizzicato")
        #expect(Extra.pizzicato.values.isEmpty)
    }

    @Test
    func slurEnd() {
        #expect(Extra.slurEnd.name == "slurEnd")
        #expect(Extra.slurEnd.values.isEmpty)
    }

    @Test
    func slurStart() {
        #expect(Extra.slurStart.name == "slurStart")
        #expect(Extra.slurStart.values.isEmpty)
    }

    @Test
    func staccato() {
        #expect(Extra.staccato.name == "staccato")
        #expect(Extra.staccato.values.isEmpty)
    }

    @Test
    func tenuto() {
        #expect(Extra.tenuto.name == "tenuto")
        #expect(Extra.tenuto.values.isEmpty)
    }

    @Test
    func trill() {
        #expect(Extra.trill.name == "trill")
        #expect(Extra.trill.values.isEmpty)
    }

    @Test
    func turn() {
        #expect(Extra.turn.name == "turn")
        #expect(Extra.turn.values.isEmpty)
    }

    @Test
    func upBow() {
        #expect(Extra.upBow.name == "upBow")
        #expect(Extra.upBow.values.isEmpty)
    }

    @Test
    func accentAndSlurStart_roundTripThroughNoteTableEntry() {
        var table = NoteTableSB()

        table.insert(attack: 0,
                     duration: 1,
                     pitch: .c4,
                     extras: Extras(elements: [Extra(name: Extra.accent.name, values: []),
                                               Extra(name: Extra.slurStart.name,
                                                     values: [.string("1")])]))

        var foundAccent = false
        var foundSlurID: String?

        table.forEach { _, _, _, _, _, extras in
            for extra in extras?.elements ?? [] {
                if extra.name == Extra.accent.name {
                    foundAccent = true
                } else if extra.name == Extra.slurStart.name,
                          case let .string(value)? = extra.values.first {
                    foundSlurID = value
                }
            }
        }

        #expect(foundAccent)
        #expect(foundSlurID == "1")
    }
}
