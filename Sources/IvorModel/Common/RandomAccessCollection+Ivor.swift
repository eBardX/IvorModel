// © 2026 John Gary Pusey (see LICENSE.md)

extension RandomAccessCollection {

    // MARK: Internal Instance Methods

    //
    // The index of the first element for which `belongsInSecondPartition` is true, or
    // `endIndex` if there is none, found by binary search. The collection must already be
    // partitioned by the predicate: every element for which it is false comes before every
    // element for which it is true. The tables and maps keep their entries sorted, so this
    // finds an insertion point or the start of a run of equal times in O(log n) rather than
    // the O(n) of `firstIndex(where:)`, which made building a long table one entry at a
    // time quadratic.
    //
    internal func partitioningIndex(where belongsInSecondPartition: (Element) throws -> Bool) rethrows -> Index {
        var low = startIndex
        var remaining = distance(from: low, to: endIndex)

        while remaining > 0 {
            let half = remaining / 2
            let mid = index(low, offsetBy: half)

            if try belongsInSecondPartition(self[mid]) {
                remaining = half
            } else {
                low = index(after: mid)
                remaining -= half + 1
            }
        }

        return low
    }
}
