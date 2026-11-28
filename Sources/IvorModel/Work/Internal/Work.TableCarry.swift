// © 2026 John Gary Pusey (see LICENSE.md)

extension Work {

    // MARK: Internal Nested Types

    //
    // How much of one table a transform carries along with its notes: all of it, only the given
    // entries, or none of it.
    //
    internal enum TableCarry {
        case all
        case entries(Set<EntryID>)
        case none
    }
}

// MARK: -

extension Work.TableCarry {

    // MARK: Internal Type Methods

    //
    // Applies `transform` to `table` with the entries `carry` names: every entry (`nil`) for
    // `.all`, the given ones for `.entries`, and not at all for `.none`.
    //
    internal static func apply<Table, Failure: Swift.Error>(_ carry: Self,
                                                            to table: inout Table,
                                                            _ transform: (inout Table, Set<EntryID>?) throws(Failure) -> Void) throws(Failure) {
        switch carry {
        case .all:
            try transform(&table, nil)

        case let .entries(entryIDs):
            try transform(&table, entryIDs)

        case .none:
            break
        }
    }
}

// MARK: - Equatable

extension Work.TableCarry: Equatable {
}

// MARK: - Sendable

extension Work.TableCarry: Sendable {
}
