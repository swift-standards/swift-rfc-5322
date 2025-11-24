//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 24/11/2025.
//

// MARK: - Header Error Type

extension RFC_5322.Header {
    /// Header-specific error type for typed throws
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Invalid header format (missing colon separator)
        case invalidFormat(String, reason: String)

        /// Invalid header name
        case invalidName(RFC_5322.Header.Name.Error)

        /// Invalid header value
        case invalidValue(RFC_5322.Header.Value.Error)
    }
}
