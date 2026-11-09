// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct TemplateGenerationOptionsLengthTests {
}

// MARK: -

extension TemplateGenerationOptionsLengthTests {
    @Test
    func codable() throws {
        let lengths: [StandardBeatOptions.Length] = [.duration(beats(8)), .noteCount(20)]

        for length in lengths {
            let data = try JSONEncoder().encode(length)
            let decoded = try JSONDecoder().decode(StandardBeatOptions.Length.self,
                                                   from: data)

            #expect(decoded == length)
        }
    }

    @Test
    func hashable() {
        let lengths: Set<StandardBeatOptions.Length> = [.duration(beats(8)), .duration(beats(8)), .noteCount(8)]

        #expect(lengths.count == 2)
    }

    @Test
    func isReached_duration() {
        let length = StandardBeatOptions.Length.duration(beats(4))

        #expect(!length.isReached(noteCount: 100, time: 3))
        #expect(length.isReached(noteCount: 0, time: 4))
        #expect(length.isReached(noteCount: 0, time: 5))
    }

    @Test
    func isReached_noteCount() {
        let length = StandardBeatOptions.Length.noteCount(3)

        #expect(!length.isReached(noteCount: 2, time: 100))
        #expect(length.isReached(noteCount: 3, time: 0))
    }

    @Test
    func isValid_duration() {
        #expect(StandardBeatOptions.Length.duration(beats(1)).isValid)
        #expect(!StandardBeatOptions.Length.duration(.zero).isValid)
    }

    @Test
    func isValid_noteCount() {
        #expect(StandardBeatOptions.Length.noteCount(1).isValid)
        #expect(!StandardBeatOptions.Length.noteCount(0).isValid)
        #expect(!StandardBeatOptions.Length.noteCount(-1).isValid)
    }
}
