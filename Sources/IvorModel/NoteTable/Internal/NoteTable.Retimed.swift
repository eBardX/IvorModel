// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming

extension NoteTable {

    // MARK: Internal Type Aliases

    internal typealias Retimed<NewTimeType: TimeProtocol> = NoteTable<NewTimeType, PitchType>
}
