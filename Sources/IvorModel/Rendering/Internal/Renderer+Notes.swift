// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiNumbers
internal import XestiTools

extension Renderer {

    // MARK: Internal Instance Methods

    //
    // The rendered notes of one written note: its grace notes, one per pitch of each event, and
    // the pieces of the main note over the span it has left (see `pieces(of:from:to:)`). The
    // main pitch's last piece carries the glide, if the note has one; the others sit on its start
    // pitch. A figure tied to the main note lends the tied event's span to the main note instead
    // of sounding it: a figure before extends the first piece back, a figure after the last piece
    // on. A main note left with no span sounds only its grace notes. A grace note, and a piece on
    // a partner pitch other than the main pitch, is an ornament note (see `Extra.ornamentNote`);
    // every piece on the main pitch, a repeated tremolo's included, is not.
    //
    internal func renderedNotes(of index: Int) -> [Note] {
        let source = sources[index]
        var before = beforeEvents[index]
        var after = afterEvents[index]
        var pieces = starts[index] < ends[index] ? pieces(of: index, from: starts[index], to: ends[index]) : []

        if source.ornamentation?.graceBefore?.isTiedToMainNote ?? false,
           let first = pieces.first,
           first.partner == nil,
           let tied = before.indices.last,
           let pitch = before[tied].pitches.firstIndex(of: source.startPitch) {
            pieces[0].start = before[tied].start
            before[tied].pitches.remove(at: pitch)
        }

        if source.ornamentation?.graceAfter?.isTiedToMainNote ?? false,
           let last = pieces.last,
           last.partner == nil,
           let tied = after.indices.first,
           let pitch = after[tied].pitches.firstIndex(of: source.endPitch) {
            pieces[pieces.count - 1].end = after[tied].end
            after[tied].pitches.remove(at: pitch)
        }

        let lastMain = pieces.lastIndex { $0.partner == nil }
        var notes: [Note] = []

        for (position, piece) in pieces.enumerated() where piece.start < piece.end {
            for pitch in piece.partner ?? [source.startPitch] {
                let extras = Self._extras(source.extras,
                                          isFirst: position == 0,
                                          isLast: position == pieces.count - 1,
                                          isOrnamentNote: piece.partner != nil && pitch != source.startPitch)

                notes.append(Note(end: piece.end,
                                  endPitch: piece.partner == nil && position == lastMain ? source.endPitch : pitch,
                                  extras: extras,
                                  start: piece.start,
                                  startPitch: pitch))
            }
        }

        for event in before + after where event.start < event.end {
            for pitch in event.pitches {
                notes.append(Note(end: event.end,
                                  endPitch: pitch,
                                  extras: Self.ornamentNoteExtras,
                                  start: event.start,
                                  startPitch: pitch))
            }
        }

        return notes
    }

    // MARK: Private Type Properties

    private static var ornamentNoteExtras: Extras {
        Extras(elements: [.ornamentNote])
    }

    // MARK: Private Type Methods

    //
    // The extras a piece of a main note keeps. One piece keeps them all. Otherwise every piece
    // keeps the attack velocity; the first keeps the rest, such as a slur's start and
    // articulations, but the last takes what belongs to the note's end: a slur's end, a breath
    // mark and the release velocity. Grace notes get none. An ornament note is flagged too.
    //
    private static func _extras(_ extras: Extras?,
                                isFirst: Bool,
                                isLast: Bool,
                                isOrnamentNote: Bool) -> Extras? {
        let kept = Self._extras(extras,
                                isFirst: isFirst,
                                isLast: isLast)

        guard isOrnamentNote
        else { return kept }

        return (kept ?? Extras()).inserting(.ornamentNote)
    }

    private static func _extras(_ extras: Extras?,
                                isFirst: Bool,
                                isLast: Bool) -> Extras? {
        guard let extras,
              !(isFirst && isLast)
        else { return extras }

        let endNames = [Extra.breathMark.name, Extra.releaseVelocity.name, Extra.slurEnd.name]
        let kept = extras.elements.filter { extra in
            if extra.name == Extra.attackVelocity.name {
                return true
            }

            return endNames.contains(extra.name) ? isLast : isFirst
        }

        return kept.isEmpty ? nil : Extras(elements: kept)
    }
}
