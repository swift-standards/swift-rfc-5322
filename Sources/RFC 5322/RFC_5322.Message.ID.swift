//
//  RFC_5322.Message.ID.swift
//  swift-rfc-5322
//
//  RFC 5322 Message-ID implementation
//

import INCITS_4_1986

extension RFC_5322.Message {
    /// RFC 5322 compliant Message-ID
    ///
    /// Format: `<unique-string@domain>`
    ///
    /// Per RFC 5322 Section 3.6.4:
    /// - Must be globally unique
    /// - Enclosed in angle brackets
    /// - Contains local-part @ domain
    /// - Should use a domain under the sender's control
    ///
    /// ## Storage
    ///
    /// Stores the Message-ID as canonical `[UInt8]` (ASCII bytes without angle brackets).
    /// This follows the same pattern as `LocalPart` for academic correctness and zero-copy serialization.
    public struct ID: Hashable, Sendable {
        /// The unique identifier bytes (without angle brackets)
        /// Stored in format: "unique-string@domain" as ASCII bytes
        package let value: [UInt8]
        
        /// Initialize with pre-formatted Message-ID bytes
        ///
        /// - Parameter value: The Message-ID bytes without angle brackets
        internal init(unchecked value: [UInt8]) {
            self.value = value
        }
    }
}

extension RFC_5322.Message.ID {
    /// Generate a Message-ID for an email address with a unique identifier
    ///
    /// - Parameters:
    ///   - uniqueId: A unique string (timestamp, UUID, etc.)
    ///   - domain: The domain to use (typically from sender's email)
    public init(uniqueId: String, domain: RFC_1123.Domain) {
        var result = [UInt8]()
        result.append(utf8: uniqueId)
        result.append(.ascii.at)
        result.append(utf8: domain.name)
        self.value = result
    }
}

extension RFC_5322.Message.ID {
    /// Parses a Message-ID from canonical byte representation (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 5322 Message-IDs are ASCII-only.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_5322.Message.ID (structured data)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [UInt8] (UTF-8 bytes) → Message.ID
    /// ```
    ///
    /// ## Format
    ///
    /// Parses Message-ID format: `<unique-string@domain>` or `unique-string@domain`
    /// Angle brackets are optional in parsing but required in serialization per RFC 5322.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array("<abc123@example.com>".utf8)
    /// let messageId = try RFC_5322.Message.ID(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the Message-ID
    /// - Throws: `RFC_5322.Message.ID.Error` if the bytes are malformed
    public init(ascii bytes: [UInt8]) throws(Error) {
        // Remove angle brackets if present
        var processedBytes = bytes[...]
        if bytes.first == .ascii.lt && bytes.last == .ascii.gt {
            processedBytes = bytes.dropFirst().dropLast()
        }

        // Validate format: must contain @ sign
        guard processedBytes.contains(.ascii.at) else {
            let string = String(decoding: bytes, as: UTF8.self)
            throw Error.missingAtSign(string)
        }

        // Validate all characters are valid (printable ASCII, no spaces)
        for byte in processedBytes {
            guard byte.ascii.isVisible && byte != .ascii.space else {
                let string = String(decoding: bytes, as: UTF8.self)
                throw Error.invalidCharacter(string, byte: byte, reason: "Must be printable ASCII without spaces")
            }
        }

        self.value = Array(processedBytes)
    }
}

extension RFC_5322.Message.ID {
    /// Initialize from string representation (STRING CONVENIENCE)
    ///
    /// Composes through canonical byte representation for academic correctness.
    ///
    /// ## Category Theory
    ///
    /// Parsing composes as:
    /// ```
    /// String → [UInt8] (UTF-8) → Message.ID
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let messageId = try RFC_5322.Message.ID("<abc123@example.com>")
    /// ```
    ///
    /// - Parameter string: The string representation of the Message-ID
    /// - Throws: `RFC_5322.Message.ID.Error` if the string is malformed
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: Array(string.utf8))
    }
}

extension [UInt8] {
    /// Creates RFC 5322 formatted Message-ID bytes (CANONICAL SERIALIZATION)
    ///
    /// This is the canonical byte-level serialization of RFC 5322 Message-IDs.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental serialization transformation:
    /// - **Domain**: RFC_5322.Message.ID (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// Message.ID → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ## Format
    ///
    /// Produces RFC 5322 Message-ID format: `<unique-string@domain>`
    /// Always includes angle brackets per RFC 5322 Section 3.6.4.
    ///
    /// ## Performance
    ///
    /// Zero-copy: Directly wraps stored byte array with angle brackets.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let messageId = RFC_5322.Message.ID(uniqueId: "abc123", domain: "example.com")
    /// let bytes = [UInt8](messageId)
    /// // bytes == "<abc123@example.com>" as ASCII bytes
    /// ```
    ///
    /// - Parameter messageId: The Message-ID to serialize
    public init(_ messageId: RFC_5322.Message.ID) {
        var result = [UInt8]()
        result.reserveCapacity(messageId.value.count + 2) // +2 for angle brackets

        // Always include angle brackets per RFC 5322
        result.append(.ascii.lt)
        result.append(contentsOf: messageId.value)
        result.append(.ascii.gt)

        self = result
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
    public init(_ value: RFC_5322.Message.ID) {
        self = Self(decoding: [UInt8](value), as: UTF8.self)
    }
}

extension RFC_5322.Message.ID: CustomStringConvertible {
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
    public var description: String {
        String(decoding: [UInt8](self), as: UTF8.self)
    }
}

extension RFC_5322.Message.ID: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        // Encode as string (without angle brackets)
        let string = String(decoding: self.value, as: UTF8.self)
        try container.encode(string)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        // Use the string initializer which validates format
        try self.init(string)
    }
}

extension RFC_5322.Message.ID: ExpressibleByStringLiteral {
    /// Creates a Message-ID from a string literal
    ///
    /// Note: This uses force-try for convenience with literals.
    /// Prefer `init(_:)` for runtime strings with error handling.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let id: RFC_5322.Message.ID = "<abc@example.com>"
    /// ```
    public init(stringLiteral value: String) {
        try! self.init(value)
    }
}
