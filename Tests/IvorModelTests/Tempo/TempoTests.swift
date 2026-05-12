@testable import IvorModel
import Testing

struct TempoTests {
}

// MARK: -

extension TempoTests {
    @Test
    func comparable() throws {
        let t60 = try #require(Tempo(uintValue: 60))
        let t120 = try #require(Tempo(uintValue: 120))

        #expect(t60 < t120)
        #expect(t60 == .default)
    }

    @Test
    func `default`() {
        #expect(Tempo.default.uintValue == 60)
    }

    @Test
    func doubleValue() throws {
        let t120 = try #require(Tempo(uintValue: 120))

        #expect(t120.doubleValue == 120.0)
    }

    @Test
    func init_invalid() {
        #expect(Tempo(uintValue: 0) == nil)
    }

    @Test
    func init_valid() {
        #expect(Tempo(uintValue: 1) != nil)
        #expect(Tempo(uintValue: 60) != nil)
        #expect(Tempo(uintValue: 240) != nil)
    }
}
