//
//  RFC_5322.Error.swift
//  swift-rfc-5322
//
//  Unified error type for RFC 5322 operations
//  Designed to support future typed throws while maintaining backward compatibility
//

extension RFC_5322 {
    /// Unified error type for all RFC 5322 operations
    ///
    /// This error type wraps domain-specific errors from different RFC 5322 components,
    /// providing a single error type for use with Swift's future typed throws feature.
    ///
    /// ## Usage with Typed Throws (Future Swift)
    ///
    /// ```swift
    /// func parseDateTime(_ string: String) throws(RFC_5322.Error) -> RFC_5322.DateTime {
    ///     // ...
    /// }
    /// ```
    ///
    /// ## Current Usage
    ///
    /// Functions can still throw domain-specific errors, which can be converted to
    /// `RFC_5322.Error` when needed.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Date/time related errors (parsing, validation, component ranges)
        case dateTime(Date.Error)

        /// Email address validation errors
        case emailAddress(EmailAddress.ValidationError)

        /// Generic parsing error for unspecified format issues
        case invalidFormat(String)

        /// Invalid header field name per RFC 5322 Section 3.6.8
        case invalidFieldName(String, reason: String)

        /// Underlying error details as a string description
        public var errorDescription: String {
            switch self {
            case .dateTime(let error): return String(describing: error)
            case .emailAddress(let error): return String(describing: error)
            case .invalidFormat(let message): return message
            case .invalidFieldName(let name, let reason): return "Invalid field name '\(name)': \(reason)"
            }
        }
    }
}

// MARK: - Convenience Conversions

extension RFC_5322.Date.Error {
    /// Convert to unified RFC_5322.Error
    public var unified: RFC_5322.Error {
        .dateTime(self)
    }
}

extension RFC_5322.EmailAddress.ValidationError {
    /// Convert to unified RFC_5322.Error
    public var unified: RFC_5322.Error {
        .emailAddress(self)
    }
}

// MARK: - CustomStringConvertible

extension RFC_5322.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .dateTime(let error):
            return "DateTime error: \(error)"
        case .emailAddress(let error):
            return "Email address error: \(error)"
        case .invalidFormat(let message):
            return "Invalid format: \(message)"
        case .invalidFieldName(let name, let reason):
            return "Invalid field name '\(name)': \(reason)"
        }
    }
}
