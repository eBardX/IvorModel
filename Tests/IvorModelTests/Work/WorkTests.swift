// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorSMPTE
import IvorTiming
import IvorTuning
import Testing

struct WorkTests {
}

// MARK: -

extension WorkTests {
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
        let original = Work(name: "Quartet", content: .standardBeat([part], TempoMap()))
        let duplicate = original.duplicated()

        #expect(duplicate.workID != original.workID)
        #expect(duplicate.name == original.name)
        #expect(duplicate.partCount == original.partCount)
        #expect(duplicate.partName(at: 0) == original.partName(at: 0))
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
    func init_name() {
        let work = Work(name: "Symphony No. 1")

        #expect(work.name == "Symphony No. 1")
        #expect(work.version == Work.currentVersion)
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
    func partCount_empty() {
        let work = Work(content: .standardBeat([], TempoMap()))

        #expect(work.partCount == 0)
    }

    @Test
    func partCount_nonEmpty() {
        let part = Part<BeatTime, Pitch>(name: "Piano")
        let work = Work(content: .standardBeat([part], TempoMap()))

        #expect(work.partCount == 1)
    }

    @Test
    func partName() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        let work = Work(content: .standardBeat([part], TempoMap()))

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
        let work = Work(content: .standardBeat([], TempoMap()))

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
    func replaceContent() throws {
        var work = Work(content: .standardWall([]))
        let part = Part<WallTime, Pitch>(name: "Cello")

        try work.replaceContent(with: .standardWall([part]))

        #expect(work.partIDs == [part.partID])
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
        let work = Work(content: .standardBeat([], TempoMap()))

        #expect(work.tempoMap != nil)
    }

    @Test
    func tempoMap_wall() {
        let work = Work(content: .standardWall([]))

        #expect(work.tempoMap == nil)
    }

    @Test
    func timeBasis_beat() {
        let work = Work(content: .standardBeat([], TempoMap()))

        #expect(work.timeBasis == .beat)
    }

    @Test
    func timeBasis_wall() {
        let work = Work(content: .standardWall([]))

        #expect(work.timeBasis == .wall)
    }
}
