@testable import IvorModel
import Testing

struct PS13Tests {
}

// MARK: -

extension PS13Tests {
    @Test
    func outputCount_matchesInputCount() {
        let ocpList: [OrderedChromaticPitch] = [OrderedChromaticPitch(time: 0, pitch: 39),
                                                OrderedChromaticPitch(time: 1, pitch: 43),
                                                OrderedChromaticPitch(time: 2, pitch: 46),
                                                OrderedChromaticPitch(time: 3, pitch: 47),
                                                OrderedChromaticPitch(time: 4, pitch: 42),
                                                OrderedChromaticPitch(time: 5, pitch: 39),
                                                OrderedChromaticPitch(time: 6, pitch: 38),
                                                OrderedChromaticPitch(time: 7, pitch: 43),
                                                OrderedChromaticPitch(time: 8, pitch: 47),
                                                OrderedChromaticPitch(time: 9, pitch: 46),
                                                OrderedChromaticPitch(time: 10, pitch: 43),
                                                OrderedChromaticPitch(time: 11, pitch: 39)]

        let result = ps13s1(sortedOCPList: ocpList, kpre: 10, kpost: 42)

        #expect(result.count == ocpList.count)
    }

    @Test
    func outputTimes_matchInputTimes() {
        let ocpList: [OrderedChromaticPitch] = [OrderedChromaticPitch(time: 0, pitch: 48),
                                                OrderedChromaticPitch(time: 1, pitch: 52),
                                                OrderedChromaticPitch(time: 2, pitch: 55)]

        let result = ps13s1(sortedOCPList: ocpList, kpre: 1, kpost: 1)

        #expect(result.count == 3)
        #expect(result[0].time == 0)
        #expect(result[1].time == 1)
        #expect(result[2].time == 2)
    }

    @Test
    func emptyInput() {
        let result = ps13s1(sortedOCPList: [], kpre: 1, kpost: 1)

        #expect(result.isEmpty)
    }
}
