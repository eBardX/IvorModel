// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

extension Part {

    // MARK: Internal Nested Types

    //
    // The table rule's two cases for one carry plan (see `Part.carryPlan(for:applyTo:alsoCarry:)`):
    // a table several strands share, and a strand's own.
    //
    internal struct TableRule {

        // MARK: Internal Instance Properties

        internal let applyTo: TransformTargets
        internal let alsoCarry: TransformTargets

        //
        // The chosen notes' time range across every strand.
        //
        internal let noteTimeRange: ClosedRange<TimeType>?

        //
        // Each strand's chosen notes' time range, by strand index.
        //
        internal let strandRanges: [ClosedRange<TimeType>?]

        internal let strandSelections: [Work.StrandSelection?]
    }
}

// MARK: -

extension Part.TableRule {

    // MARK: Internal Instance Properties

    //
    // Whether the plan takes some strands, every one of them whole.
    //
    internal var takesWholeStrandsOnly: Bool {
        let chosen = strandSelections.compactMap(\.self)

        return !chosen.isEmpty && chosen.allSatisfy { $0 == .whole }
    }

    // MARK: Internal Instance Methods

    //
    // How much of a strand's own table of `kind` is carried: all of it for a whole strand, the
    // entries `entries` finds within its chosen notes' range for some of its notes, and none if
    // the strand isn't chosen.
    //
    internal func own(_ kind: TransformTargets,
                      at index: Int,
                      entries: (ClosedRange<TimeType>) -> Set<EntryID>) -> Work.TableCarry {
        guard applyTo.contains(kind),
              let strandSelection = strandSelections[index]
        else { return .none }

        guard strandSelection != .whole
        else { return .all }

        return .entries(strandRanges[index].map(entries) ?? [])
    }

    //
    // How much of a shared table of `kind` is carried: all of it when it's `covered`; else, if
    // `alsoCarry` opts it in, all of it for whole strands only, or the entries `entries` finds
    // within the chosen notes' range.
    //
    internal func shared(_ kind: TransformTargets,
                         covered: Bool,
                         entries: (ClosedRange<TimeType>) -> Set<EntryID>) -> Work.TableCarry {
        guard applyTo.contains(kind)
        else { return .none }

        if covered {
            return .all
        }

        guard alsoCarry.contains(kind)
        else { return .none }

        if takesWholeStrandsOnly {
            return .all
        }

        return .entries(noteTimeRange.map(entries) ?? [])
    }
}

// MARK: - Sendable

extension Part.TableRule: Sendable {
}
