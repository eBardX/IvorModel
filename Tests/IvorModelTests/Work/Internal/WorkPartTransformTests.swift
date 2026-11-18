// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing

struct WorkPartTransformTests {
}

// MARK: -

extension WorkPartTransformTests {
    @Test
    func partTransform_mutatesPartInPlace() throws {
        let transform: Work.PartTransform<BeatTime, Pitch> = { part in
            part.name = "Renamed"
        }
        var part = Part<BeatTime, Pitch>(name: "Original")

        try transform(&part)

        #expect(part.name == "Renamed")
    }

    @Test
    func partTransform_throwsPartError() {
        let transform: Work.PartTransform<WallTime, NoteNumber> = { _ in
            throw .panMapFailure(.invalidAnchor)
        }
        var part = Part<WallTime, NoteNumber>(name: "Piano")

        #expect(throws: Part<WallTime, NoteNumber>.Error.self) {
            try transform(&part)
        }
    }
}
