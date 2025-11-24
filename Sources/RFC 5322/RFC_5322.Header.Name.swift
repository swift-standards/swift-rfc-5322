//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

import INCITS_4_1986

// MARK: - Header.Name

extension RFC_5322.Header {
    /// Email header field name
    ///
    /// Represents header field names in Internet Message Format as defined by RFC 5322.
    /// Header field names are case-insensitive per the specification.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let from: Self = fro
    /// let custom: Self = "X-Custom-Header"
    ///
    /// var headers: [RFC_5322.Header] = []
    /// headers.append(.init(name: .messageId, value: "<abc@example.com>"))
    /// headers.append(.init(name: .contentType, value: "text/plain"))
    /// ```
    ///
    /// ## RFC Reference
    ///
    /// From RFC 5322 Section 2.2:
    ///
    /// > Field names are comprised of printable US-ASCII characters except colon.
    /// > Field names are case-insensitive.
    ///
    /// ## Common Header Names
    ///
    /// Standard RFC 5322 headers are available as static properties:
    /// - `from`, `to`, `cc`, `bcc`: Address headers
    /// - `subject`: Subject line
    /// - `date`: Date and time
    /// - `messageId`: Unique message identifier
    ///
    /// MIME headers (RFC 2045) are also included:
    /// - `contentType`: Media type of content
    /// - `contentTransferEncoding`: Encoding mechanism
    /// - `mimeVersion`: MIME version
    ///
    /// Custom headers can be created using the string-based initializer.
    public struct Name: Hashable, Sendable, Codable {
        /// The header field name
        public let rawValue: String

        /// Creates a header name
        ///
        /// - Parameter rawValue: The header field name (case-insensitive)
        public init(_ rawValue: String) {
            // Header names are case-insensitive, but we preserve original case
            // for display purposes while using case-insensitive comparison
            self.rawValue = rawValue
        }

        /// Hash value (case-insensitive)
        public func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue.lowercased())
        }

        /// Equality comparison (case-insensitive)
        public static func == (lhs: RFC_5322.Header.Name, rhs: RFC_5322.Header.Name) -> Bool {
            lhs.rawValue.lowercased() == rhs.rawValue.lowercased()
        }
    }
}



// MARK: - Header.Name Parsing

extension RFC_5322.Header.Name {
    /// Parses a header name from canonical byte representation (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 5322 header names are ASCII-only.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_5322.Header.Name (structured data)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [UInt8] (UTF-8 bytes) → Header.Name
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array("Content-Type".utf8)
    /// let name = try RFC_5322.Header.Name(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the header name
    /// - Throws: `RFC_5322.Header.Name.Error` if the bytes are malformed
    public init(ascii bytes: [UInt8]) throws(Error) {
        // Empty check
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        // Validate characters: printable ASCII except colon
        // ftext = %d33-57 / %d59-126
        // Using INCITS_4_1986: .ascii.isVisible (0x21-0x7E) excludes colon (0x3A)
        for byte in bytes {
            // Must be visible ASCII (0x21-0x7E) but not colon (0x3A/58)
            guard byte.ascii.isVisible && byte != .ascii.colon else {
                let string = String(decoding: bytes, as: UTF8.self)
                let reason = byte == .ascii.colon
                    ? "Field name cannot contain colon"
                    : "Must be printable ASCII except colon"
                throw Error.invalidCharacter(string, byte: byte, reason: reason)
            }
        }

        // Store the validated string
        let string = String(decoding: bytes, as: UTF8.self)
        self.init(string)
    }
}

// MARK: - Validation

extension RFC_5322.Header.Name {
    /// Creates a validated header field name
    ///
    /// Composes through canonical byte representation for academic correctness.
    /// Validates the field name against RFC 5322 Section 3.6.8 grammar.
    ///
    /// - Parameter value: Field name to validate
    /// - Throws: `RFC_5322.Error.invalidFieldName` if invalid
    ///
    /// ## Category Theory
    ///
    /// Parsing composes as:
    /// ```
    /// String → [UInt8] (UTF-8) → Header.Name
    /// ```
    ///
    /// ## RFC 5322 Section 3.6.8 Grammar
    ///
    /// ```
    /// field-name = 1*ftext
    /// ftext      = %d33-57 / %d59-126  ; Printable ASCII except colon
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let valid = try RFC_5322.Header.Name(validating: "X-Custom-Header")
    /// let invalid = try RFC_5322.Header.Name(validating: "X:Bad")  // Throws
    /// ```
    public init(_ value: some StringProtocol) throws(Error) {
        // Convert to canonical byte representation (UTF-8, which is ASCII-compatible)
        let bytes = Array(value.utf8)

        // Delegate to primitive byte-level parser
        try self.init(ascii: bytes)
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
    public init(_ value: RFC_5322.Header.Name) {
        self = Self(decoding: [UInt8](value), as: UTF8.self)
    }
}

// MARK: - RFC 5322 Standard Headers

extension RFC_5322.Header.Name {
    /// From: header (originator)
    public static let from: Self = "From"

    /// To: header (primary recipients)
    public static let to: Self = "To"

    /// Cc: header (carbon copy recipients)
    public static let cc: Self = "Cc"

    /// Bcc: header (blind carbon copy recipients)
    public static let bcc: Self = "Bcc"

    /// Subject: header
    public static let subject: Self = "Subject"

    /// Date: header
    public static let date: Self = "Date"

    /// Message-ID: header (unique message identifier)
    public static let messageId: Self = "Message-ID"

    /// Reply-To: header
    public static let replyTo: Self = "Reply-To"

    /// Sender: header (actual sender if different from From)
    public static let sender: Self = "Sender"

    /// In-Reply-To: header (message being replied to)
    public static let inReplyTo: Self = "In-Reply-To"

    /// References: header (related messages)
    public static let references: Self = "References"

    /// Resent-From: header
    public static let resentFrom: Self = "Resent-From"

    /// Resent-To: header
    public static let resentTo: Self = "Resent-To"

    /// Resent-Date: header
    public static let resentDate: Self = "Resent-Date"

    /// Resent-Message-ID: header
    public static let resentMessageId: Self = "Resent-Message-ID"

    /// Return-Path: header
    public static let returnPath: Self = "Return-Path"

    /// Received: header (mail transfer path)
    public static let received: Self = "Received"
}

// MARK: - Common Extension Headers

extension RFC_5322.Header.Name {
    /// X-Mailer: header (mail client identification)
    public static let xMailer: Self = "X-Mailer"

    /// X-Priority: header (message priority)
    public static let xPriority: Self = "X-Priority"

    /// List-Unsubscribe: header (mailing list unsubscribe)
    public static let listUnsubscribe: Self = "List-Unsubscribe"

    /// List-ID: header (mailing list identifier)
    public static let listId: Self = "List-ID"

    /// Precedence: header
    public static let precedence: Self = "Precedence"

    /// Auto-Submitted: header
    public static let autoSubmitted: Self = "Auto-Submitted"
}

// MARK: - Apple Mail Headers

extension RFC_5322.Header.Name {
    /// X-Apple-Base-Url: header
    public static let xAppleBaseUrl: Self = "X-Apple-Base-Url"

    /// X-Universally-Unique-Identifier: header
    public static let xUniversallyUniqueIdentifier: Self = "X-Universally-Unique-Identifier"

    /// X-Apple-Mail-Remote-Attachments: header
    public static let xAppleMailRemoteAttachments: Self = "X-Apple-Mail-Remote-Attachments"

    /// X-Apple-Windows-Friendly: header
    public static let xAppleWindowsFriendly: Self = "X-Apple-Windows-Friendly"

    /// X-Apple-Mail-Signature: header
    public static let xAppleMailSignature: Self = "X-Apple-Mail-Signature"

    /// X-Uniform-Type-Identifier: header
    public static let xUniformTypeIdentifier: Self = "X-Uniform-Type-Identifier"
}

// MARK: - Name Protocol Conformances

extension RFC_5322.Header.Name: ExpressibleByStringLiteral {
    /// Creates a header name from a string literal
    ///
    /// Allows convenient syntax: `let header: Header.Name = "X-Custom"`
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension RFC_5322.Header.Name: CustomStringConvertible {
    /// Returns the header field name
    public var description: String {
        rawValue
    }
}
