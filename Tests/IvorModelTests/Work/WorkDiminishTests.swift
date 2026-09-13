// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct WorkDiminishTests {
}

// MARK: -

extension WorkDiminishTests {
    @Test
    func diminish_wrongTimeBasisThrows() {
        var work = Work(content: .standardWall([]))

        #expect(throws: Work.Error.timeBasisMismatch(expected: .beat)) {
            try work.diminish(by: Number(2), anchor: nil as BeatTime?)
        }
    }
}
