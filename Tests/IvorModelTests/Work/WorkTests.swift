// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorSMPTE
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkTests {
}

// MARK: -

extension WorkTests {
    @Test
    func codable_extrasRoundTrip() throws {
        let work = Work(name: "Cue", extras: makeTimeCodeExtras())
        let decoded = try JSONDecoder().decode(Work.self, from: JSONEncoder().encode(work))

        #expect(decoded.extras == work.extras)
    }

    @Test
    func codable_infoRoundTrips() throws {
        let work = Work(name: "Aubade", info: makeWorkInfo())
        let decoded = try JSONDecoder().decode(Work.self, from: JSONEncoder().encode(work))

        #expect(decoded.info == work.info)
    }

    @Test
    func codable_missingInfoIsError() throws {
        let data = try JSONEncoder().encode(Work(name: "Cue"))
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["info"] != nil)

        object["info"] = nil

        let badData = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Work.self, from: badData)
        }
    }

    @Test
    func codable_noExtrasOmitsKey() throws {
        let data = try JSONEncoder().encode(Work(name: "Cue"))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["extras"] == nil)
        #expect(try JSONDecoder().decode(Work.self, from: data).extras == nil)
    }

    @Test
    func codable_normalizesName() throws {
        let data = try JSONEncoder().encode(Work(name: "Cue"))
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        object["name"] = "  Sketch \t 3 "

        let decoded = try JSONDecoder().decode(Work.self,
                                               from: JSONSerialization.data(withJSONObject: object))

        #expect(decoded.name == "Sketch 3")
    }

    @Test
    func codable_omitsNilRules() throws {
        let data = try JSONEncoder().encode(Work(name: "Plain"))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["interpretationRules"] == nil)
    }

    @Test
    func codable_roundTripsRulesAndPartMarks() throws {
        let work = makeRuledWork()
        let decoded = try JSONDecoder().decode(Work.self, from: JSONEncoder().encode(work))
        let part = try #require(standardBeatParts(of: decoded).first)

        #expect(decoded.interpretationRules == ruledWorkRules())
        #expect(part.interpretationRules == ruledPartRules())
        #expect(part.markTable.map(\.mark) == [.caesura(nil)])
        #expect(part.markTable.map(\.time) == [1])
    }

    @Test
    func codable_sharedNoteIDsDecodeDistinct() throws {
        // Note IDs are never saved (see `NoteID`), so decoding gives every note a fresh one:
        // even a work built with shared IDs (`Work.init` doesn't check) decodes with none.
        let (violin, cello) = Self._partsSharingNotes()
        let data = try JSONEncoder().encode(Work(content: .standardBeat([violin, cello], TempoMap(), MeterTable(), KeyTable())))
        let decoded = try JSONDecoder().decode(Work.self, from: data)

        #expect(decoded.noteCount == 4)
        #expect(decoded.content.firstDuplicateNoteID == nil)
    }

    @Test
    func comparable() {
        let alpha = Work(name: "Alpha")
        let beta  = Work(name: "Beta")

        #expect(alpha < beta)
        #expect(!(beta < alpha))
    }

    @Test
    func currentVersion() {
        #expect(Work.currentVersion == 1)
    }

    @Test
    func duplicated() {
        let part = Part<BeatTime, Pitch>(name: "Viola")
        let original = Work(name: "Quartet", content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))
        let duplicate = original.duplicated()

        #expect(duplicate.workID != original.workID)
        #expect(duplicate.name == original.name)
        #expect(duplicate.partCount == original.partCount)
        #expect(duplicate.partName(at: 0) == original.partName(at: 0))
    }

    @Test
    func duplicated_keepsExtras() {
        let original = Work(name: "Cue", extras: makeTimeCodeExtras())

        #expect(original.duplicated().extras == original.extras)
    }

    @Test
    func duplicated_keepsInfo() {
        let original = Work(name: "Aubade", info: makeWorkInfo())

        #expect(original.duplicated().info == original.info)
    }

    @Test
    func duplicated_keepsRules() {
        #expect(makeRuledWork().duplicated().interpretationRules == ruledWorkRules())
    }

    @Test
    func duplicated_ofLockedWork_isUnlocked() {
        var original = Work(name: "Quartet")

        original.isLocked = true

        #expect(!original.duplicated().isLocked)
    }

    @Test
    func equality() {
        let work = Work(name: "My Work")

        #expect(work == work)   // swiftlint:disable:this identical_operands
    }

    @Test
    func equality_ignoresExtras() throws {
        var work = Work(name: "Cue")
        let original = work

        try work.modifyExtras { $0 = makeTimeCodeExtras() }

        #expect(work == original)
    }

    @Test
    func equality_ignoresInfo() {
        var work = Work(name: "Aubade")
        let original = work

        try? work.modifyInfo { $0.title = "Dawn" }

        #expect(work == original)
    }

    @Test
    func inequality() {
        let work1 = Work(name: "My Work")
        let work2 = Work(name: "My Work")

        #expect(work1 != work2)
    }

    @Test
    func init_defaults() {
        let work = Work()

        #expect(work.name.isEmpty)
        #expect(work.version == Work.currentVersion)
    }

    @Test
    func init_emptyExtrasBecomeNil() {
        #expect(Work(extras: Extras()).extras == nil)
    }

    @Test
    func init_emptyRulesAreStoredAsNil() {
        #expect(Work(interpretationRules: InterpretationRules()).interpretationRules == nil)
    }

    @Test
    func init_extras() {
        #expect(Work(name: "Cue", extras: makeTimeCodeExtras()).extras == makeTimeCodeExtras())
    }

    @Test
    func init_extrasDefaultToNil() {
        #expect(Work().extras == nil)
    }

    @Test
    func init_info() {
        let work = Work(name: "Aubade", info: makeWorkInfo())

        #expect(work.info == makeWorkInfo())
    }

    @Test
    func init_infoDefaultsToEmpty() {
        #expect(Work().info == Work.Info())
    }

    @Test
    func init_name() {
        let work = Work(name: "Symphony No. 1")

        #expect(work.name == "Symphony No. 1")
        #expect(work.version == Work.currentVersion)
    }

    @Test
    func init_normalizesName() {
        #expect(Work(name: "  Sketch  3\n").name == "Sketch 3")
        #expect(Work(name: " \t ").name.isEmpty)
    }

    @Test
    func isLocked_default() {
        let work = Work()

        #expect(!work.isLocked)
    }

    @Test
    func isLocked_unlockingAllowsContentReplacement() throws {
        var work = Work(content: .standardWall([]))
        let part = Part<WallTime, Pitch>(name: "Cello")

        work.isLocked = true
        work.isLocked = false

        try work.replaceContent(with: .standardWall([part]))

        #expect(work.partCount == 1)
    }

    @Test
    func meterTable_wallWork_isNil() {
        let work = Work(content: .empty(timeBasis: .wall, pitchNotation: .standard))

        #expect(work.meterTable == nil)
    }

    @Test
    func modifyExtras() throws {
        var work = Work(name: "Cue")

        let result = try work.modifyExtras { extras in
            extras = makeTimeCodeExtras()

            return 42
        }

        #expect(result == 42)
        #expect(work.extras == makeTimeCodeExtras())
    }

    @Test
    func modifyExtras_emptyExtrasBecomeNil() throws {
        var work = Work(name: "Cue", extras: makeTimeCodeExtras())

        try work.modifyExtras { $0 = Extras() }

        #expect(work.extras == nil)
    }

    @Test
    func modifyExtras_lockedWork_throws() {
        var work = Work(name: "Cue")

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.modifyExtras { $0 = makeTimeCodeExtras() }
        }
        #expect(work.extras == nil)
    }

    @Test
    func modifyInfo() throws {
        var work = Work(name: "Aubade")

        let result = try work.modifyInfo { info in
            info.title = " Aubade  in C "

            return 42
        }

        #expect(result == 42)
        #expect(work.info.title == "Aubade in C")
    }

    @Test
    func modifyInfo_lockedWork_throws() {
        var work = Work(name: "Aubade")

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.modifyInfo { $0.title = "Dawn" }
        }
        #expect(work.info.title == nil)
    }

    @Test
    func partCount_empty() {
        let work = Work(content: .standardBeat([], TempoMap(), MeterTable(), KeyTable()))

        #expect(work.partCount == 0)
    }

    @Test
    func partCount_nonEmpty() {
        let part = Part<BeatTime, Pitch>(name: "Piano")
        let work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        #expect(work.partCount == 1)
    }

    @Test
    func partName() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        let work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        #expect(work.partName(at: 0) == "Violin")
    }

    @Test
    func pitchNotation_absolute() {
        let work = Work(content: .absoluteWall([]))

        #expect(work.pitchNotation == .absolute)
    }

    @Test
    func pitchNotation_keyboard() {
        let work = Work(content: .keyboardWall([]))

        #expect(work.pitchNotation == .keyboard)
    }

    @Test
    func pitchNotation_standard() {
        let work = Work(content: .standardBeat([], TempoMap(), MeterTable(), KeyTable()))

        #expect(work.pitchNotation == .standard)
    }

    @Test
    func rename() throws {
        var work = Work(name: "Original")

        try work.rename(to: "Renamed")

        #expect(work.name == "Renamed")
    }

    @Test
    func rename_lockedWork_throws() {
        var work = Work(name: "Original")

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.rename(to: "Renamed")
        }
        #expect(work.name == "Original")
    }

    @Test
    func rename_normalizesName() throws {
        var work = Work(name: "Aubade")

        try work.rename(to: "  Sketch\n3 ")

        #expect(work.name == "Sketch 3")
    }

    @Test
    func replaceContent() throws {
        var work = Work(content: .standardWall([]))
        let part = Part<WallTime, Pitch>(name: "Cello")

        try work.replaceContent(with: .standardWall([part]))

        #expect(work.partIDs == [part.partID])
    }

    @Test
    func replaceContent_duplicateNoteID_throws() throws {
        var work = Work(content: .standardBeat([], TempoMap(), MeterTable(), KeyTable()))
        let (violin, cello) = Self._partsSharingNotes()
        let sharedID = try #require(violin.strands[0].noteTable.first?.noteID)

        #expect(throws: Work.Error.duplicateNoteID(sharedID)) {
            try work.replaceContent(with: .standardBeat([violin, cello], TempoMap(), MeterTable(), KeyTable()))
        }
        #expect(work.partIDs.isEmpty)
    }

    @Test
    func replaceContent_duplicateNoteIDWithinOnePart_throws() throws {
        var work = Work(content: .standardBeat([], TempoMap(), MeterTable(), KeyTable()))
        let (violin, _) = Self._partsSharingNotes()
        var doubled = violin.strands[0].noteTable

        doubled.merge(with: violin.strands[0].noteTable)

        let part = Part<BeatTime, Pitch>(name: "Violin", noteTable: doubled)

        #expect(throws: try Work.Error.duplicateNoteID(#require(violin.strands[0].noteTable.first?.noteID))) {
            try work.replaceContent(with: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))
        }
        #expect(work.partIDs.isEmpty)
    }

    @Test
    func replaceContent_duplicatePartID_throws() {
        var work = Work(content: .standardWall([]))
        let part = Part<WallTime, Pitch>(name: "Cello")

        #expect(throws: Work.Error.duplicatePartID(part.partID)) {
            try work.replaceContent(with: .standardWall([part, part]))
        }
        #expect(work.partIDs.isEmpty)
    }

    @Test
    func replaceContent_lockedWork_throws() {
        var work = Work(content: .standardWall([]))
        let part = Part<WallTime, Pitch>(name: "Cello")

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.replaceContent(with: .standardWall([part]))
        }
        #expect(work.partCount == 0)
    }

    @Test
    func setInterpretationRules() throws {
        var work = Work()

        try work.setInterpretationRules(ruledWorkRules())

        #expect(work.interpretationRules == ruledWorkRules())

        try work.setInterpretationRules(InterpretationRules())

        #expect(work.interpretationRules == nil)
    }

    @Test
    func setInterpretationRules_lockedWork() {
        var (work, _) = makeLockedWorkSB()

        #expect(throws: Work.Error.workIsLocked) {
            try work.setInterpretationRules(ruledWorkRules())
        }

        #expect(work.interpretationRules == nil)
    }

    @Test
    func setSMPTEStartTime() throws {
        var work = Work()
        let startTime = try #require(SMPTETime(string: "01:00:00:00", frameRate: .fps25))

        try work.setSMPTEStartTime(startTime)

        #expect(work.smpteStartTime == startTime)
    }

    @Test
    func setSMPTEStartTime_lockedWork_throws() throws {
        var work = Work()
        let startTime = try #require(SMPTETime(string: "01:00:00:00", frameRate: .fps25))

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.setSMPTEStartTime(startTime)
        }
        #expect(work.smpteStartTime == Work.defaultSMPTEStartTime)
    }

    @Test
    func smpteStartTime_decodesInvalidAsError() throws {
        let data = try JSONEncoder().encode(Work(name: "Cue"))
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        object["smpteStartTime"] = ["25", "01:00:00:99"]

        let badData = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Work.self, from: badData)
        }
    }

    @Test
    func smpteStartTime_default() {
        let startTime = Work().smpteStartTime

        #expect(startTime == Work.defaultSMPTEStartTime)
        #expect(startTime.frameRate == .fps25)
        #expect(startTime.description == "00:00:00:00")
    }

    @Test
    func smpteStartTime_duplicated() throws {
        let original = try Work(name: "Cue",
                                smpteStartTime: #require(SMPTETime(string: "01:00:00:00", frameRate: .fps25)))

        #expect(original.duplicated().smpteStartTime == original.smpteStartTime)
    }

    @Test
    func smpteStartTime_missingIsError() throws {
        let data = try JSONEncoder().encode(Work(name: "Cue"))
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        object["smpteStartTime"] = nil

        let badData = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Work.self, from: badData)
        }
    }

    @Test
    func smpteStartTime_roundTrips() throws {
        var work = Work(name: "Cue", content: .standardWall([]))

        try work.setSMPTEStartTime(#require(SMPTETime(string: "01:00:00;02", frameRate: .fps2997Drop)))

        let decoded = try JSONDecoder().decode(Work.self, from: JSONEncoder().encode(work))

        #expect(decoded.smpteStartTime == work.smpteStartTime)
    }

    @Test
    func tempoMap_beat() {
        let work = Work(content: .standardBeat([], TempoMap(), MeterTable(), KeyTable()))

        #expect(work.tempoMap != nil)
    }

    @Test
    func tempoMap_wall() {
        let work = Work(content: .standardWall([]))

        #expect(work.tempoMap == nil)
    }

    @Test
    func timeBasis_beat() {
        let work = Work(content: .standardBeat([], TempoMap(), MeterTable(), KeyTable()))

        #expect(work.timeBasis == .beat)
    }

    @Test
    func timeBasis_wall() {
        let work = Work(content: .standardWall([]))

        #expect(work.timeBasis == .wall)
    }

    // MARK: Private Type Methods

    //
    // Two parts holding the same notes, identities and all, which no work may contain.
    //
    private static func _partsSharingNotes() -> (Part<BeatTime, Pitch>, Part<BeatTime, Pitch>) {
        var noteTable = NoteTable<BeatTime, Pitch>()

        noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        noteTable.insert(attack: 1, duration: 1, pitch: .e4)

        return (Part(name: "Violin", noteTable: noteTable),
                Part(name: "Cello", noteTable: noteTable))
    }
}
