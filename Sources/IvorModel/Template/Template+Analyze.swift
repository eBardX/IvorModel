// © 2025–2026 John Gary Pusey (see LICENSE.md)

private import XestiMarkov

extension Template {

    // MARK: Public Type Methods

    /// Creates a template by analyzing the note events of a specific part in a work.
    ///
    /// - Parameter work:           The ``Work`` containing the part to analyze.
    /// - Parameter index:          The zero-based index of the part to analyze.
    /// - Parameter maximumOrder:   The maximum pattern depth for the analysis.
    ///
    /// - Returns:  A new ``Template`` capturing the musical character of the specified part.
    ///
    /// - Throws:   ``Template/Error/invalidMaximumOrder`` if `maximumOrder` is not positive;
    ///             otherwise, ``Template/Error/partNotFound(_:)`` if no part exists at `index`.
    public static func analyzeNoteEvents(in work: Work,
                                         at index: Int,
                                         maximumOrder: Int) throws -> Self {
        let name = if work.name.isEmpty {
            "Analysis of \(work.workID)"
        } else {
            "Analysis of “\(work.name)”"
        }

        return try Self(name: name,
                        content: _analyzeNoteEvents(in: work.content,
                                                    at: index,
                                                    maximumOrder: maximumOrder))
    }

    // MARK: Private Type Methods

    private static func _analyzeNoteEvents(in content: Work.Content,
                                           at index: Int,
                                           maximumOrder: Int) throws -> Self.Content {
        switch content {
        case let .absoluteBeat(parts, _):
            try .absoluteBeat(_analyzeNoteEvents(in: parts,
                                                 at: index,
                                                 maximumOrder: maximumOrder))

        case let .absoluteWall(parts):
            try .absoluteWall(_analyzeNoteEvents(in: parts,
                                                 at: index,
                                                 maximumOrder: maximumOrder))

        case let .keyboardBeat(parts, _):
            try .keyboardBeat(_analyzeNoteEvents(in: parts,
                                                 at: index,
                                                 maximumOrder: maximumOrder))

        case let .keyboardWall(parts):
            try .keyboardWall(_analyzeNoteEvents(in: parts,
                                                 at: index,
                                                 maximumOrder: maximumOrder))

        case let .standardBeat(parts, _):
            try .standardBeat(_analyzeNoteEvents(in: parts,
                                                 at: index,
                                                 maximumOrder: maximumOrder))

        case let .standardWall(parts):
            try .standardWall(_analyzeNoteEvents(in: parts,
                                                 at: index,
                                                 maximumOrder: maximumOrder))
        }
    }

    private static func _analyzeNoteEvents<T, P>(in parts: [Part<T, P>],
                                                 at index: Int,
                                                 maximumOrder: Int) throws -> MarkovChain<NoteEvent<T, P>> {
        guard let markovChain = MarkovChain<NoteEvent<T, P>>(maximumOrder: maximumOrder)
        else { throw Error.invalidMaximumOrder }

        let noteEvents = try _extractNoteEvents(from: parts,
                                                at: index)

        markovChain.analyzer().analyze(sequence: noteEvents)

        return markovChain
    }

    private static func _extractNoteEvents<T, P>(from parts: [Part<T, P>],
                                                 at index: Int) throws -> [NoteEvent<T, P>] {
        for (idx, part) in parts.enumerated() where index == idx {
            return try part.noteTable.extractNoteEvents()
        }

        throw Error.partNotFound(index)
    }
}
