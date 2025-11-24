//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

import INCITS_4_1986

// MARK: - Header.Value

extension RFC_5322.Header {
    public struct Value: Hashable, Sendable, Codable {
        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        /// Hash value (case-insensitive)
        public func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue.lowercased())
        }

        /// Equality comparison (case-insensitive)
        public static func == (lhs: RFC_5322.Header.Value, rhs: RFC_5322.Header.Value) -> Bool {
            lhs.rawValue.lowercased() == rhs.rawValue.lowercased()
        }
    }
}



// MARK: - Header.Value Parsing

extension RFC_5322.Header.Value {
    /// Parses a header value from canonical byte representation (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 5322 headers are ASCII with folding whitespace rules.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_5322.Header.Value (structured data)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [UInt8] (UTF-8 bytes) → Header.Value
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array("text/html; charset=UTF-8".utf8)
    /// let value = try RFC_5322.Header.Value(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the header value
    /// - Throws: `RFC_5322.Header.Value.Error` if the bytes are malformed
    public init(ascii bytes: [UInt8]) throws(Error) {
        // Decode bytes as UTF-8 (which is ASCII-compatible)
        let string = String(decoding: bytes, as: UTF8.self)

        // For now, we accept any string
        // In the future, we could validate RFC 5322 folding whitespace rules
        // and throw Error.invalidFolding or Error.invalidCharacter
        self.rawValue = string
    }
}

extension StringProtocol {
    /// String representation of the Message-ID
    ///
    /// Composes through canonical byte representation for academic correctness.
    ///
    /// ## Category Theory
    ///
    /// String display composes as:
    /// ```
    /// Message.ID → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    public init(_ value: RFC_5322.Header.Value) {
        self = Self(decoding: [UInt8](value), as: UTF8.self)
    }
}

extension RFC_5322.Header.Value {
    /// Initialize from string representation (STRING CONVENIENCE)
    ///
    /// Composes through canonical byte representation for academic correctness.
    ///
    /// ## Category Theory
    ///
    /// Parsing composes as:
    /// ```
    /// String → [UInt8] (UTF-8) → Header.Value
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let value = try RFC_5322.Header.Value("text/html; charset=UTF-8")
    /// ```
    ///
    /// - Parameter string: The string representation of the header value
    /// - Throws: `RFC_5322.Header.Value.Error` if the string is malformed
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: Array(string.utf8))
    }
}

// MARK: - Value Protocol Conformances

extension RFC_5322.Header.Value: ExpressibleByStringLiteral {
    /// Creates a header name from a string literal
    ///
    /// Allows convenient syntax: `let header: Header.Value = "X-Custom"`
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension RFC_5322.Header.Value: ExpressibleByIntegerLiteral {
    /// Creates a header name from a string literal
    ///
    /// Allows convenient syntax: `let header: Header.Value = "X-Custom"`
    public init(integerLiteral value: Int) {
        self.init(String(value))
    }
}

extension RFC_5322.Header.Value: CustomStringConvertible {
    /// Returns the header field name
    public var description: String {
        rawValue
    }
}
