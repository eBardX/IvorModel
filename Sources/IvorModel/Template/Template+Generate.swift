private import IvorTiming
private import XestiMarkov
private import XestiTools

extension Template {

    // MARK: Public Instance Methods

    public func generateWork(name: String,
                             order: Int,
                             limit: Int) throws -> Work {
        try Self._generateWork(from: content,
                               named: name,
                               order: order,
                               limit: limit)
    }

    // MARK: Private Type Methods

    private static func _generateNoteTable<T, P>(using markovChain: MarkovChain<NoteEvent<T, P>>,
                                                 order: Int,
                                                 limit: Int) throws -> NoteTable<T, P> {
        guard limit > 0
        else { throw Error.invalidLimit }

        guard var generator = markovChain.generator(order: order)
        else { throw Error.invalidOrder(markovChain.maximumOrder) }

        var noteTable = NoteTable<T, P>()
        var nextAttack: T = .zero

        for noteEvent in generator.generate(upTo: limit) {
            for tiedPitch in noteEvent.tiedPitches {
                noteTable.insert(attack: nextAttack,
                                 duration: noteEvent.duration,
                                 pitch: tiedPitch.pitch)
            }

            nextAttack = nextAttack.moved(by: noteEvent.duration,
                                          direction: .forward).require()
        }

        return noteTable
    }

    private static func _generatePart<T, P>(using markovChain: MarkovChain<NoteEvent<T, P>>,
                                            order: Int,
                                            limit: Int) throws -> Part<T, P> {
        try Part(name: "Generated, order: \(order), limit: \(limit)",
                 noteTable: _generateNoteTable(using: markovChain,
                                               order: order,
                                               limit: limit))
    }

    private static func _generateWork(from content: Template.Content,
                                      named name: String,
                                      order: Int,
                                      limit: Int) throws -> Work {
        try Work(name: name,
                 content: _generateWorkContent(from: content,
                                               order: order,
                                               limit: limit))
    }

    private static func _generateWorkContent(from content: Template.Content,
                                             order: Int,
                                             limit: Int) throws -> Work.Content {
        switch content {
        case let .absoluteBeat(markovChain):
            try .absoluteBeat([_generatePart(using: markovChain,
                                             order: order,
                                             limit: limit)],
                              TempoMap())

        case let .absoluteWall(markovChain):
            try .absoluteWall([_generatePart(using: markovChain,
                                             order: order,
                                             limit: limit)])

        case let .keyboardBeat(markovChain):
            try .keyboardBeat([_generatePart(using: markovChain,
                                             order: order,
                                             limit: limit)],
                              TempoMap())

        case let .keyboardWall(markovChain):
            try .keyboardWall([_generatePart(using: markovChain,
                                             order: order,
                                             limit: limit)])

        case let .standardBeat(markovChain):
            try .standardBeat([_generatePart(using: markovChain,
                                             order: order,
                                             limit: limit)],
                              TempoMap())

        case let .standardWall(markovChain):
            try .standardWall([_generatePart(using: markovChain,
                                             order: order,
                                             limit: limit)])
        }
    }
}
