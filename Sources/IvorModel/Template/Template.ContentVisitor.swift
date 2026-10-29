// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension Template {
    /// A type that works with a template’s model at its concrete time and
    /// pitch types.
    ///
    /// A template’s ``Template/Content`` holds one of six ``Template/Model``
    /// types, one for each combination of time basis and pitch notation. Rather than
    /// switch over all six cases, write the code once, generically, in a
    /// visitor’s ``visit(_:)`` method, and pass the visitor to
    /// ``Template/accept(_:)``.
    public protocol ContentVisitor {

        // MARK: Public Associated Types

        /// The type of value the visitor returns.
        associatedtype Result

        // MARK: Public Instance Methods

        /// Visits a template’s model.
        ///
        /// - Parameter model:  The template’s model.
        ///
        /// - Returns:  The result of the visit.
        func visit<TimeType>(_ model: Model<TimeType, some Any>) -> Result where TimeType.DurationType: TemplateDuration
    }
}
