// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Extra.Name {

    // MARK: Public Type Methods

    /// Returns the given name in the form Ivor uses: lower camel case, starting with a lowercase
    /// letter.
    ///
    /// A name that matches a known extra’s apart from case becomes that extra’s name (see
    /// ``Extra/definitions``), so `"METERSYMBOL"` becomes `"meterSymbol"`. Any other name has the
    /// run of capitals it starts with lowercased — but for the last, if a lowercase letter follows
    /// it, since that one starts the next word: `"Accent"` becomes `"accent"`, `"SMPTETimeCode"`
    /// becomes `"smpteTimeCode"`, and `"URL"` becomes `"url"`. A name that already starts with a
    /// lowercase letter is returned as it is.
    ///
    /// - Parameter name:   The name to normalize.
    ///
    /// - Returns:  The normalized name.
    public static func normalized(_ name: Self) -> Self {
        let stringValue = name.stringValue
        let folded = stringValue.lowercased()

        if let known = Extra.definitions.first(where: { $0.name.stringValue.lowercased() == folded }) {
            return known.name
        }

        let characters = Array(stringValue)
        let capitals = characters.prefix { $0.isUppercase }.count

        guard capitals > 0
        else { return name }

        let startsNextWord = capitals > 1
            && capitals < characters.count
            && characters[capitals].isLowercase
        let lowered = startsNextWord ? capitals - 1 : capitals

        return Self(String(characters[..<lowered]).lowercased() + String(characters[lowered...]))
    }
}
