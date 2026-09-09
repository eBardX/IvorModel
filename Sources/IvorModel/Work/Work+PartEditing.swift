// © 2026 John Gary Pusey (see LICENSE.md)

private import IvorTiming
private import IvorTuning

extension Work {

    // MARK: Public Instance Properties

    /// The IDs of the parts in this work, in order.
    public var partIDs: [PartID] {
        switch content {
        case let .absoluteBeat(parts, _):
            parts.map(\.partID)

        case let .absoluteWall(parts):
            parts.map(\.partID)

        case let .keyboardBeat(parts, _):
            parts.map(\.partID)

        case let .keyboardWall(parts):
            parts.map(\.partID)

        case let .standardBeat(parts, _):
            parts.map(\.partID)

        case let .standardWall(parts):
            parts.map(\.partID)
        }
    }

    // MARK: Public Instance Methods

    /// Appends a new, empty part to this work.
    ///
    /// - Parameter name:   The display name of the new part. Defaults to an empty string.
    ///
    /// - Returns:  The ID of the newly added part.
    @discardableResult
    public mutating func addPart(name: String = "") -> PartID {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            let part = Part<BeatTime, Frequency>(name: name)
            var newParts = parts

            newParts.append(part)

            content = .absoluteBeat(newParts, tempoMap)

            return part.partID

        case let .absoluteWall(parts):
            let part = Part<WallTime, Frequency>(name: name)
            var newParts = parts

            newParts.append(part)

            content = .absoluteWall(newParts)

            return part.partID

        case let .keyboardBeat(parts, tempoMap):
            let part = Part<BeatTime, NoteNumber>(name: name)
            var newParts = parts

            newParts.append(part)

            content = .keyboardBeat(newParts, tempoMap)

            return part.partID

        case let .keyboardWall(parts):
            let part = Part<WallTime, NoteNumber>(name: name)
            var newParts = parts

            newParts.append(part)

            content = .keyboardWall(newParts)

            return part.partID

        case let .standardBeat(parts, tempoMap):
            let part = Part<BeatTime, Pitch>(name: name)
            var newParts = parts

            newParts.append(part)

            content = .standardBeat(newParts, tempoMap)

            return part.partID

        case let .standardWall(parts):
            let part = Part<WallTime, Pitch>(name: name)
            var newParts = parts

            newParts.append(part)

            content = .standardWall(newParts)

            return part.partID
        }
    }

    /// Duplicates the part with the given ID, inserting the copy immediately after
    /// the original.
    ///
    /// - Parameter partID: The ID of the part to duplicate.
    ///
    /// - Returns:  The ID of the newly added duplicate, or `nil` if no part with
    ///             `partID` was found.
    @discardableResult
    public mutating func duplicatePart(_ partID: PartID) -> PartID? {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return nil }

            let duplicate = parts[index].duplicated()
            var newParts = parts

            newParts.insert(duplicate,
                            at: index + 1)

            content = .absoluteBeat(newParts, tempoMap)

            return duplicate.partID

        case let .absoluteWall(parts):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return nil }

            let duplicate = parts[index].duplicated()
            var newParts = parts

            newParts.insert(duplicate,
                            at: index + 1)

            content = .absoluteWall(newParts)

            return duplicate.partID

        case let .keyboardBeat(parts, tempoMap):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return nil }

            let duplicate = parts[index].duplicated()
            var newParts = parts

            newParts.insert(duplicate,
                            at: index + 1)

            content = .keyboardBeat(newParts, tempoMap)

            return duplicate.partID

        case let .keyboardWall(parts):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return nil }

            let duplicate = parts[index].duplicated()
            var newParts = parts

            newParts.insert(duplicate,
                            at: index + 1)

            content = .keyboardWall(newParts)

            return duplicate.partID

        case let .standardBeat(parts, tempoMap):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return nil }

            let duplicate = parts[index].duplicated()
            var newParts = parts

            newParts.insert(duplicate,
                            at: index + 1)

            content = .standardBeat(newParts, tempoMap)

            return duplicate.partID

        case let .standardWall(parts):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return nil }

            let duplicate = parts[index].duplicated()
            var newParts = parts

            newParts.insert(duplicate,
                            at: index + 1)

            content = .standardWall(newParts)

            return duplicate.partID
        }
    }

    /// Returns the zero-based index of the part with the given ID.
    ///
    /// - Parameter partID: The ID of the part to locate.
    ///
    /// - Returns:  The zero-based index of the part with `partID`, or `nil` if no
    ///             such part is found.
    public func index(ofPartID partID: PartID) -> Int? {
        switch content {
        case let .absoluteBeat(parts, _):
            parts.firstIndex { $0.partID == partID }

        case let .absoluteWall(parts):
            parts.firstIndex { $0.partID == partID }

        case let .keyboardBeat(parts, _):
            parts.firstIndex { $0.partID == partID }

        case let .keyboardWall(parts):
            parts.firstIndex { $0.partID == partID }

        case let .standardBeat(parts, _):
            parts.firstIndex { $0.partID == partID }

        case let .standardWall(parts):
            parts.firstIndex { $0.partID == partID }
        }
    }

    /// Moves the part with the given ID to the given index, clamping to the valid
    /// range of indices. No-ops if no part with `partID` is found.
    ///
    /// - Parameter partID: The ID of the part to move.
    /// - Parameter index:  The zero-based index to move the part to.
    public mutating func movePart(_ partID: PartID,
                                  to index: Int) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            guard let currentIndex = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts
            let part = newParts.remove(at: currentIndex)

            newParts.insert(part,
                            at: Self._clamp(index, to: newParts.count))

            content = .absoluteBeat(newParts, tempoMap)

        case let .absoluteWall(parts):
            guard let currentIndex = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts
            let part = newParts.remove(at: currentIndex)

            newParts.insert(part,
                            at: Self._clamp(index, to: newParts.count))

            content = .absoluteWall(newParts)

        case let .keyboardBeat(parts, tempoMap):
            guard let currentIndex = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts
            let part = newParts.remove(at: currentIndex)

            newParts.insert(part,
                            at: Self._clamp(index, to: newParts.count))

            content = .keyboardBeat(newParts, tempoMap)

        case let .keyboardWall(parts):
            guard let currentIndex = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts
            let part = newParts.remove(at: currentIndex)

            newParts.insert(part,
                            at: Self._clamp(index, to: newParts.count))

            content = .keyboardWall(newParts)

        case let .standardBeat(parts, tempoMap):
            guard let currentIndex = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts
            let part = newParts.remove(at: currentIndex)

            newParts.insert(part,
                            at: Self._clamp(index, to: newParts.count))

            content = .standardBeat(newParts, tempoMap)

        case let .standardWall(parts):
            guard let currentIndex = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts
            let part = newParts.remove(at: currentIndex)

            newParts.insert(part,
                            at: Self._clamp(index, to: newParts.count))

            content = .standardWall(newParts)
        }
    }

    /// Removes the part with the given ID. No-ops if no part with `partID` is found.
    ///
    /// - Parameter partID: The ID of the part to remove.
    public mutating func removePart(_ partID: PartID) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts

            newParts.remove(at: index)

            content = .absoluteBeat(newParts, tempoMap)

        case let .absoluteWall(parts):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts

            newParts.remove(at: index)

            content = .absoluteWall(newParts)

        case let .keyboardBeat(parts, tempoMap):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts

            newParts.remove(at: index)

            content = .keyboardBeat(newParts, tempoMap)

        case let .keyboardWall(parts):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts

            newParts.remove(at: index)

            content = .keyboardWall(newParts)

        case let .standardBeat(parts, tempoMap):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts

            newParts.remove(at: index)

            content = .standardBeat(newParts, tempoMap)

        case let .standardWall(parts):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts

            newParts.remove(at: index)

            content = .standardWall(newParts)
        }
    }

    /// Renames the part with the given ID. No-ops if no part with `partID` is found.
    ///
    /// - Parameter partID: The ID of the part to rename.
    /// - Parameter name:   The new display name for the part.
    public mutating func renamePart(_ partID: PartID,
                                    to name: String) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts

            newParts[index].name = name

            content = .absoluteBeat(newParts, tempoMap)

        case let .absoluteWall(parts):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts

            newParts[index].name = name

            content = .absoluteWall(newParts)

        case let .keyboardBeat(parts, tempoMap):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts

            newParts[index].name = name

            content = .keyboardBeat(newParts, tempoMap)

        case let .keyboardWall(parts):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts

            newParts[index].name = name

            content = .keyboardWall(newParts)

        case let .standardBeat(parts, tempoMap):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts

            newParts[index].name = name

            content = .standardBeat(newParts, tempoMap)

        case let .standardWall(parts):
            guard let index = parts.firstIndex(where: { $0.partID == partID })
            else { return }

            var newParts = parts

            newParts[index].name = name

            content = .standardWall(newParts)
        }
    }

    // MARK: Private Type Methods

    private static func _clamp(_ index: Int,
                               to count: Int) -> Int {
        min(max(index, 0), count)
    }
}
