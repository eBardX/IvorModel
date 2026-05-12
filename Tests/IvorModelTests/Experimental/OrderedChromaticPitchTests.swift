@testable import IvorModel
import Testing

struct OrderedChromaticPitchTests {
}

// MARK: -

extension OrderedChromaticPitchTests {
    @Test
    func comparable() {
        let earlier = OrderedChromaticPitch(time: 0, pitch: 60)
        let later   = OrderedChromaticPitch(time: 1, pitch: 48)

        #expect(earlier < later)
        #expect(!(later < earlier))
    }

    @Test
    func init_properties() {
        let ocp = OrderedChromaticPitch(time: 5, pitch: 64)

        #expect(ocp.time == 5)
        #expect(ocp.pitch == 64)
    }
}
