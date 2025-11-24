//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 24/11/2025.
//

// MARK: - Errors
extension RFC_5322.EmailAddress {
    /// Error type for RFC 5322 email address parsing
    ///
    /// Follows compositional error pattern: EmailAddress delegates to LocalPart and Domain,
    /// so this error wraps their errors rather than duplicating cases.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Missing @ separator between local-part and domain
        case missingAtSign

        /// Local-part validation failed
        case localPart(RFC_5322.EmailAddress.LocalPart.Error)

        /// Domain validation failed (RFC 1123)
        case domain(RFC_1123.Domain.Error)
    }
}
