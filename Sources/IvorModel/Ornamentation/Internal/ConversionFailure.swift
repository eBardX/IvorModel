// © 2026 John Gary Pusey (see LICENSE.md)

//
// Thrown by the internal `converted(…)` helpers of the ornamentation and fermata types when a
// value can't be carried into another time or pitch type: a length that converts to zero, or a
// rebuilt value that no longer passes its own checks. The conversions catch it and drop what
// failed (or fail as a whole, as the caller decides).
//
internal struct ConversionFailure {
}

// MARK: - Error

extension ConversionFailure: Error {
}
