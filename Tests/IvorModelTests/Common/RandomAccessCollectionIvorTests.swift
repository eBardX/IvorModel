// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct RandomAccessCollectionIvorTests {
}

// MARK: -

extension RandomAccessCollectionIvorTests {
    @Test
    func partitioningIndex_allInFirstPartition() {
        #expect([1, 2, 3].partitioningIndex { $0 > 5 } == 3)
    }

    @Test
    func partitioningIndex_allInSecondPartition() {
        #expect([1, 2, 3].partitioningIndex { $0 > 0 } == 0)
    }

    @Test
    func partitioningIndex_empty() {
        #expect([Int]().partitioningIndex { $0 > 0 } == 0)
    }

    @Test
    func partitioningIndex_matchesFirstIndexOnSortedArrays() {
        for count in 0...17 {
            let values = (0..<count).map { $0 / 3 }

            for threshold in -1...7 {
                let expected = values.firstIndex { $0 > threshold } ?? values.endIndex

                #expect(values.partitioningIndex { $0 > threshold } == expected)
            }
        }
    }

    @Test
    func partitioningIndex_slice() {
        let values = [0, 1, 1, 2, 3, 5, 8]
        let slice = values[2...5]

        #expect(slice.partitioningIndex { $0 >= 2 } == 3)
        #expect(slice.partitioningIndex { $0 > 9 } == 6)
    }

    @Test
    func partitioningIndex_startOfRunOfEqualValues() {
        let values = [0, 1, 1, 1, 2]

        #expect(values.partitioningIndex { $0 >= 1 } == 1)
        #expect(values.partitioningIndex { $0 > 1 } == 4)
    }
}
