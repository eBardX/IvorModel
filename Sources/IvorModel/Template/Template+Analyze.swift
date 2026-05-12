private import XestiMarkov

extension Template {

    // MARK: Public Type Methods

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
