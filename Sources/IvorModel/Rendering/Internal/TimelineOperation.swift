// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiNumbers

//
// One change to a work's timeline, as a mapping of positions (in the work's own numbers).
//
internal enum TimelineOperation {

    //
    // Time inserted at a moment: everything that starts there or later moves later; a note that
    // ends there doesn't.
    //
    case insert(at: Number, length: Number)

    //
    // A span made longer by `extra`: positions inside it spread out in proportion, and everything
    // after it moves later.
    //
    case stretch(from: Number, to: Number, extra: Number)
}

// MARK: -

extension TimelineOperation {

    // MARK: Internal Instance Properties

    internal var time: Number {
        switch self {
        case let .insert(time, _),
             let .stretch(time, _, _):
            time
        }
    }

    // MARK: Internal Instance Methods

    //
    // Where a position lands: an attack (or any entry's time), or a release, which stays put at
    // an insertion's moment.
    //
    internal func mapped(_ position: Number,
                         isRelease: Bool = false) -> Number {
        switch self {
        case let .insert(time, length):
            if position > time || (position == time && !isRelease) {
                position + length
            } else {
                position
            }

        case let .stretch(start, end, extra):
            if position <= start {
                position
            } else if position > end {
                position + extra
            } else {
                start + (position - start) * (end - start + extra) / (end - start)
            }
        }
    }
}

// MARK: - Sendable

extension TimelineOperation: Sendable {
}
