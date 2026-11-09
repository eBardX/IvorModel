// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct ProjectUnreadableWorkTests {
}

// MARK: -

extension ProjectUnreadableWorkTests {
    @Test
    func equality() {
        let workID = WorkID()

        #expect(Project.UnreadableWork(workID: workID, name: "A", reason: "Old", contents: Data([1])) // swiftlint:disable:this identical_operands
                == Project.UnreadableWork(workID: workID, name: "A", reason: "Old", contents: Data([1])))
    }

    @Test
    func hashable() {
        let workID = WorkID()
        let works: Set = [Project.UnreadableWork(workID: workID, name: "A", reason: "Old", contents: nil),
                          Project.UnreadableWork(workID: workID, name: "A", reason: "Old", contents: nil),
                          Project.UnreadableWork(workID: WorkID(), name: "A", reason: "Old", contents: nil)]

        #expect(works.count == 2)
    }

    @Test
    func inequality_differentContents() {
        let workID = WorkID()

        #expect(Project.UnreadableWork(workID: workID, name: "A", reason: "Old", contents: Data([1]))
                != Project.UnreadableWork(workID: workID, name: "A", reason: "Old", contents: Data([2])))
    }

    @Test
    func init_storesValues() {
        let workID = WorkID()
        let work = Project.UnreadableWork(workID: workID,
                                          name: "Tune",
                                          reason: "Unsupported version",
                                          contents: Data([1, 2, 3]))

        #expect(work.contents == Data([1, 2, 3]))
        #expect(work.name == "Tune")
        #expect(work.reason == "Unsupported version")
        #expect(work.workID == workID)
    }

    @Test
    func init_withoutNameOrContents() {
        let work = Project.UnreadableWork(workID: WorkID(),
                                          name: nil,
                                          reason: "Missing",
                                          contents: nil)

        #expect(work.contents == nil)
        #expect(work.name == nil)
    }
}
