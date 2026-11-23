// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTuning

// MARK: - RenderablePitch

extension NoteNumber: RenderablePitch {

    // MARK: Internal Instance Methods

    //
    // Note numbers have no spelling, so a diatonic step is a whole tone (resolution 6 of the
    // grace-notes plan).
    //
    internal func partner(on side: PartnerSide,
                          rule: PartnerRule,
                          key: Key?) -> Self? {
        guard let distance = NoteDistance(uintValue: rule == .halfStep ? 1 : 2)
        else { return nil }

        return transposed(by: DirectedInterval(interval: distance,
                                               direction: side == .above ? .ascending : .descending))
    }
}
