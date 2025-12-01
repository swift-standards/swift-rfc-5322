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
        internal init(
            __unchecked: Void,
            rawValue: [UInt8]
        ) {
            self.value = rawValue
        }
    }
}

extension RFC_5322.Message.ID: UInt8.ASCII.Serializable {
    static public func serialize<Buffer>(
        ascii messageId: RFC_5322.Message.ID,
        into buffer: inout Buffer
    ) where Buffer : RangeReplaceableCollection, Buffer.Element == UInt8 {
        buffer.reserveCapacity(messageId.value.count + 2)  // +2 for angle brackets

        // Always include angle brackets per RFC 5322
        buffer.append(.ascii.lt)
        buffer.append(contentsOf: messageId.value)
        buffer.append(.ascii.gt)
    }

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
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        // Track first and last bytes via iteration
        var firstByte: UInt8?
        var lastByte: UInt8?
        var hasAtSign = false
        var count = 0

        for byte in bytes {
            if firstByte == nil { firstByte = byte }
            lastByte = byte
            count += 1
            if byte == .ascii.at { hasAtSign = true }
        }

        // Determine if we need to strip angle brackets
        let stripBrackets = firstByte == .ascii.lt && lastByte == .ascii.gt && count >= 2

        // Validate format: must contain @ sign
        guard hasAtSign else {
            let string = String(decoding: bytes, as: UTF8.self)
            throw Error.missingAtSign(string)
        }

        // Build result while validating characters
        var result = [UInt8]()
        var isFirst = true
        var byteCount = 0

        for byte in bytes {
            byteCount += 1

            // Skip leading '<' if stripping brackets
            if stripBrackets && isFirst && byte == .ascii.lt {
                isFirst = false
                continue
            }
            // Skip trailing '>' if stripping brackets
            if stripBrackets && byteCount == count && byte == .ascii.gt {
                continue
            }
            isFirst = false

            // Validate: printable ASCII, no spaces
            guard byte.ascii.isVisible && byte != .ascii.space else {
                let string = String(decoding: bytes, as: UTF8.self)
                throw Error.invalidCharacter(
                    string,
                    byte: byte,
                    reason: "Must be printable ASCII without spaces"
                )
            }

            result.append(byte)
        }

        self.value = result
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

extension RFC_5322.Message.ID: CustomStringConvertible {}

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

extension RFC_5322.Message.ID: ExpressibleByStringLiteral {}
extension RFC_5322.Message.ID: ExpressibleByFloatLiteral {}
extension RFC_5322.Message.ID: ExpressibleByIntegerLiteral {}
