// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

extension Part {

    // MARK: Internal Nested Types

    //
    // What one transform of a part takes: the notes of each strand, and how much of each table
    // it carries along with them (see `Part.carryPlan(for:applyTo:alsoCarry:)`).
    //
    internal struct CarryPlan {

        // MARK: Internal Instance Properties

        //
        // The part's dynamic map and instrument table.
        //
        internal var dynamics: Work.TableCarry
        internal var instruments: Work.TableCarry

        internal var marks: Work.TableCarry

        //
        // The time range of the chosen notes across every strand, or `nil` if there are none.
        //
        internal var noteTimeRange: ClosedRange<TimeType>?

        internal var pan: Work.TableCarry
        internal var pedals: [Pedal: Work.TableCarry]

        //
        // Each strand's own dynamic map and instrument table, by strand index. `.none` for a
        // strand without one.
        //
        internal var strandDynamics: [Work.TableCarry]
        internal var strandInstruments: [Work.TableCarry]

        //
        // What the transform takes of each strand, by strand index: `nil` for a strand it
        // leaves alone.
        //
        internal var strandSelections: [Work.StrandSelection?]
    }
}

// MARK: - Sendable

extension Part.CarryPlan: Sendable {
}
