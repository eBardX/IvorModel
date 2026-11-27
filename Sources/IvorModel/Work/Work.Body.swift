// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Work {

    // MARK: Public Nested Types

    /// The content of a work with its concrete time and pitch types: its parts, and whatever
    /// else its time basis carries.
    ///
    /// A ``Work/Content`` holds one, as `any Work.Body`. Code that works the same way for every
    /// kind of content is written once, as a generic function over `some Work.Body`, and Swift
    /// opens the content’s body to call it. Members that don’t mention the body’s types, such as
    /// ``partCount``, can be used on `any Work.Body` directly.
    ///
    /// Bodies come in two kinds, ``Work/BeatBody`` and ``Work/WallBody``, one for each
    /// ``TimeBasis``, each generic over its pitch type. ``Work/BeatTimeBody`` narrows to the
    /// first, and ``Work/WallTimeBody`` to the second.
    public protocol Body<TimeType, PitchType>: Sendable {

        // MARK: Associated Types

        /// The time type of the body’s parts.
        associatedtype TimeType: TimeProtocol

        /// The pitch type of the body’s parts.
        associatedtype PitchType: PitchProtocol

        // MARK: Type Properties

        /// The time basis of every body of this type.
        static var timeBasis: TimeBasis { get }

        // MARK: Instance Properties

        /// The body’s parts, in score order.
        var parts: [Part<TimeType, PitchType>] { get set }
    }
}

// MARK: -

extension Work.Body {

    // MARK: Public Type Properties

    /// The pitch notation of every body of this type.
    public static var pitchNotation: PitchNotation {
        if PitchType.self == Frequency.self {
            .absolute
        } else if PitchType.self == NoteNumber.self {
            .keyboard
        } else {
            .standard
        }
    }

    // MARK: Public Instance Properties

    /// The number of notes in all of the body’s parts.
    public var noteCount: Int {
        parts.reduce(0) { $0 + $1.noteCount }
    }

    /// The number of parts in the body.
    public var partCount: Int {
        parts.count
    }

    /// The IDs of the body’s parts, in order.
    public var partIDs: [PartID] {
        parts.map(\.partID)
    }

    /// The pitch range spanned by the notes of the body’s parts, or `nil` if there are none.
    ///
    /// Both bounds are of the body’s ``PitchType``.
    public var pitchRange: (lowerBound: any PitchProtocol, upperBound: any PitchProtocol)? {
        Work.aggregatePitchRange(of: parts).map { ($0.lowerBound, $0.upperBound) }
    }

    /// The pitch notation of the body.
    public var pitchNotation: PitchNotation {
        Self.pitchNotation
    }

    /// The time basis of the body.
    public var timeBasis: TimeBasis {
        Self.timeBasis
    }

    // MARK: Public Instance Methods

    /// Returns the name of the part at the given index.
    ///
    /// - Parameter index:  The index of the part, which must be valid.
    ///
    /// - Returns:  The part’s name.
    public func partName(at index: Int) -> String {
        parts[index].name
    }

    // MARK: Internal Instance Properties

    //
    // The first part with no strands, or `nil` if every part has one.
    //
    internal var firstPartWithoutStrands: PartID? {
        parts.first { $0.strands.isEmpty }?.partID
    }

    //
    // The ID of every note of every part, in part order, and within a part in strand order.
    //
    internal var noteIDs: [NoteID] {
        parts.flatMap(\.noteIDs)
    }

    //
    // The ID of every strand of every part, in part order, and within a part in score order.
    //
    internal var strandIDs: [StrandID] {
        parts.flatMap(\.strandIDs)
    }
}
