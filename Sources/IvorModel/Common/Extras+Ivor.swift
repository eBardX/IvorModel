// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Extras {

    // MARK: Public Instance Methods

    /// Returns these extras with every name normalized (see ``Extra/Name/normalized(_:)``).
    ///
    /// Two extras whose names normalize to the same one become one, keeping the values of the one
    /// that sorts last.
    ///
    /// - Returns:  The extras, with normalized names.
    public func normalizingNames() -> Extras {
        guard elements.contains(where: { Extra.Name.normalized($0.name) != $0.name })
        else { return self }

        let normalized = elements.map {
            Extra(name: Extra.Name.normalized($0.name),
                  values: $0.values)
        }

        return Extras(elements: normalized)
    }
}
