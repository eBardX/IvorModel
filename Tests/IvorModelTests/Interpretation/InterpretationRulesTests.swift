// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct InterpretationRulesTests {
}

// MARK: -

extension InterpretationRulesTests {
    @Test
    func codable_omitsNilFields() throws {
        #expect(try encodedJSON(InterpretationRules()) == "{}")
        #expect(try encodedJSON(InterpretationRules(trill: OrnamentRules(startNote: .partner))) == #"{"trill":{"startNote":"partner"}}"#)
    }

    @Test
    func codable_readsAnEmptyNestedValueAsNil() throws {
        let rules = try decodeJSON(InterpretationRules.self, #"{"grace":{},"fermata":{}}"#)

        #expect(rules.grace == nil)
        #expect(rules.fermata == nil)
        #expect(rules.isEmpty)
    }

    @Test
    func codable_roundTrip() throws {
        let rules = fullInterpretationRules()

        #expect(try codingRoundTrip(rules) == rules)
    }

    @Test
    func init_dropsEmptyNestedValues() {
        let rules = InterpretationRules(grace: GraceRules(),
                                        trill: OrnamentRules(),
                                        mordent: OrnamentRules(),
                                        tremolo: OrnamentRules(),
                                        arpeggio: ArpeggioRules(),
                                        fermata: FermataRules())

        #expect(rules == InterpretationRules())
        #expect(rules.isEmpty)
        #expect(!fullInterpretationRules().isEmpty)
    }

    @Test
    func resolved_combinesTheWorkAndAPart() throws {
        let work = makeRuledWork()
        let part = try #require(standardBeatParts(of: work).first)
        let resolved = InterpretationRules.resolved(work: work.interpretationRules,
                                                    part: part.interpretationRules)

        #expect(resolved.caesura == positiveSeconds(3))
        #expect(resolved.arpeggio == ArpeggioRules(direction: .down))
    }

    @Test
    func resolved_partFieldsOverWorkFields() {
        let work = InterpretationRules(grace: GraceRules(slashedPlacement: .beforeBeat, maximumShare: proportion(1, 2)),
                                       trill: OrnamentRules(startNote: .partner, rate: notesPerSecond(10)),
                                       fermata: FermataRules(holds: [.normal: .stretch(fermataStretch(3)), .long: .stretch(fermataStretch(4))],
                                                             pauseAfter: positiveSeconds(1)),
                                       caesura: positiveSeconds(2))
        let part = InterpretationRules(grace: GraceRules(maximumShare: proportion(1, 4)),
                                       trill: OrnamentRules(rate: notesPerSecond(14)),
                                       mordent: OrnamentRules(partnerRule: .halfStep),
                                       fermata: FermataRules(holds: [.normal: .seconds(positiveSeconds(5))]))
        let resolved = InterpretationRules.resolved(work: work, part: part)

        #expect(resolved.grace == GraceRules(slashedPlacement: .beforeBeat, maximumShare: proportion(1, 4)))
        #expect(resolved.trill == OrnamentRules(startNote: .partner, rate: notesPerSecond(14)))
        #expect(resolved.mordent == OrnamentRules(partnerRule: .halfStep))
        #expect(resolved.tremolo == nil)
        #expect(resolved.fermata == FermataRules(holds: [.normal: .seconds(positiveSeconds(5)), .long: .stretch(fermataStretch(4))],
                                                 pauseAfter: positiveSeconds(1)))
        #expect(resolved.caesura == positiveSeconds(2))
    }

    @Test
    func resolved_withMissingLayers() {
        let rules = fullInterpretationRules()

        #expect(InterpretationRules.resolved(work: nil, part: nil) == InterpretationRules())
        #expect(InterpretationRules.resolved(work: rules, part: nil) == rules)
        #expect(InterpretationRules.resolved(work: nil, part: rules) == rules)
    }
}
