// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorSMPTE
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct SMPTETimeIvorTests {
}

// MARK: -

extension SMPTETimeIvorTests {
    @Test
    func init_frameRate_duration() {
        #expect(SMPTETime(frameRate: .fps25, duration: .zero).description == "00:00:00:00")
        #expect(SMPTETime(frameRate: .fps25, duration: WallDuration(90_000_000)).description == "00:01:30:00")
        #expect(SMPTETime(frameRate: .fps25, duration: WallDuration(20_000)).description == "00:00:00:00.50")
    }

    @Test
    func init_frameRate_duration_dropFrame() {
        #expect(SMPTETime(frameRate: .fps2997Drop, duration: WallDuration(60_060_000)).description == "00:01:00;02")
    }

    @Test
    func init_frameRate_duration_wraps() {
        #expect(SMPTETime(frameRate: .fps25, duration: WallDuration(86_401_000_000)).description == "00:00:01:00")
    }
}
