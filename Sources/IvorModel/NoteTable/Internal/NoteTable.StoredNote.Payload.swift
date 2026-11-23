// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

extension NoteTable.StoredNote {

    // MARK: Internal Nested Types

    //
    // What an `extended` note carries beyond its times and pitches. It is never empty: the
    // initializer returns `nil` unless at least one field is present, and a present field is
    // never empty, so a note with neither stays `glide` or `simple`.
    //
    internal struct Payload {

        // MARK: Internal Initializers

        internal init?(extras: Extras?,
                       ornamentation: NoteTable.Ornamentation?) {
            let extras = extras.flatMap { $0.isEmpty ? nil : $0 }
            let ornamentation = ornamentation.flatMap { $0.isEmpty ? nil : $0 }

            guard extras != nil || ornamentation != nil
            else { return nil }

            self.extras = extras
            self.ornamentation = ornamentation
        }

        // MARK: Internal Instance Properties

        internal let extras: Extras?
        internal let ornamentation: NoteTable.Ornamentation?
    }
}

// MARK: - Equatable

extension NoteTable.StoredNote.Payload: Equatable {
}

// MARK: - Sendable

extension NoteTable.StoredNote.Payload: Sendable {
}
