// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct WorkProblemSeverityTests {
}

// MARK: -

extension WorkProblemSeverityTests {
    @Test
    func allCasesAreDistinct() {
        let severities: Set<Work.Problem.Severity> = [.error, .warning]

        #expect(severities.count == 2)
    }

    @Test
    func equality() {
        #expect(Work.Problem.Severity.error == .error)
    }

    @Test
    func inequality() {
        #expect(Work.Problem.Severity.error != .warning)
    }
}
