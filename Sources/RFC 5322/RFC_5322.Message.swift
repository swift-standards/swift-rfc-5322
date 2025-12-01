//
//  RFC 5322 Message.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 12/11/2025.
//

import INCITS_4_1986
import RFC_1123
import Standards

extension RFC_5322 {
    /// RFC 5322 Internet Message Format
    ///
    /// Represents a complete RFC 5322 email message with headers and body.
    /// Can generate .eml files compliant with RFC 5322 specification.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let message = RFC_5322.Message(
    ///     from: RFC_5322.EmailAddress(
    ///         displayName: "John Doe",
    ///         localPart: .init("john"),
    ///         domain: RFC_1123.Domain("example.com")
    ///     ),
    ///     to: [RFC_5322.EmailAddress(try! .init("jane@example.com"))],
    ///     subject: "Hello!",
    ///     date: Date(),
    ///     messageId: "<unique-id@example.com>",
    ///     body: "Hello, World!"
    /// )
    ///
    /// let emlContent = message.render()
    /// ```
    public struct Message: Hashable, Sendable, Codable {
        /// Originator - From field
        public let from: EmailAddress

        /// Recipients - To field
        public let to: [EmailAddress]

        /// Carbon copy recipients
        public let cc: [EmailAddress]?

        /// Blind carbon copy recipients (not included in rendered message)
        public let bcc: [EmailAddress]?

        /// Reply-To field
        public let replyTo: EmailAddress?

        /// Subject line
        public let subject: String

        /// Message date
        public let date: RFC_5322.DateTime

        /// Unique message identifier
        public let messageId: Message.ID

        /// Message body as bytes (typically MIME content from RFC 2045/2046)
        public let body: [UInt8]

        /// Additional custom headers
        public let additionalHeaders: [Header]

        /// MIME-Version header value (defaults to "1.0")
        public let mimeVersion: String

        /// Creates an RFC 5322 message
        ///
        /// - Parameters:
        ///   - from: Originator address
        ///   - to: Recipient addresses
        ///   - cc: Carbon copy recipients
        ///   - bcc: Blind carbon copy recipients
        ///   - replyTo: Reply-to address
        ///   - subject: Subject line
        ///   - date: Message date
        ///   - messageId: Unique message identifier
        ///   - body: Message body as bytes
        ///   - additionalHeaders: Additional custom headers
        ///   - mimeVersion: MIME-Version header (defaults to "1.0")
        public init(
            from: EmailAddress,
            to: [EmailAddress],
            cc: [EmailAddress]? = nil,
            bcc: [EmailAddress]? = nil,
            replyTo: EmailAddress? = nil,
            date: RFC_5322.DateTime,
            subject: String,
            messageId: Message.ID,
            body: [UInt8],
            additionalHeaders: [Header] = [],
            mimeVersion: String = "1.0"
        ) {
            self.from = from
            self.to = to
            self.cc = cc
            self.bcc = bcc
            self.replyTo = replyTo
            self.date = date
            self.subject = subject
            self.messageId = messageId
            self.body = body
            self.additionalHeaders = additionalHeaders
            self.mimeVersion = mimeVersion
        }
    }
}

extension RFC_5322.Message: UInt8.ASCII.Serializable {
    static public func serialize<Buffer>(ascii message: RFC_5322.Message, into buffer: inout Buffer) where Buffer : RangeReplaceableCollection, Buffer.Element == UInt8 {
        
        // Pre-allocate capacity to avoid reallocations
        // Rough estimate: headers (~500 bytes) + body
        buffer.reserveCapacity(500 + message.body.count)

        // Required headers in recommended order (RFC 5322 Section 3.6)

        // From (required)
        buffer.append(contentsOf: [UInt8].fromPrefix)
        buffer.append(contentsOf: [UInt8](message.from))
        buffer.append(contentsOf: [UInt8].ascii.crlf)

        // To (required)
        buffer.append(contentsOf: [UInt8].toPrefix)
        var first = true
        for address in message.to {
            if !first { buffer.append(contentsOf: [.ascii.comma, .ascii.space]) }
            first = false
            buffer.append(contentsOf: [UInt8](address))
        }
        buffer.append(contentsOf: [UInt8].ascii.crlf)

        // Cc (optional)
        if let cc = message.cc, !cc.isEmpty {
            buffer.append(contentsOf: [UInt8].ccPrefix)
            first = true
            for address in cc {
                if !first { buffer.append(contentsOf: [.ascii.comma, .ascii.space]) }
                first = false
                buffer.append(contentsOf: [UInt8](address))
            }
            buffer.append(contentsOf: [UInt8].ascii.crlf)
        }

        // Subject (required in practice)
        buffer.append(contentsOf: [UInt8].subjectPrefix)
        buffer.append(utf8: message.subject)
        buffer.append(contentsOf: [UInt8].ascii.crlf)

        // Date (required)
        buffer.append(contentsOf: [UInt8].datePrefix)
        buffer.append(contentsOf: [UInt8](message.date))
        buffer.append(contentsOf: [UInt8].ascii.crlf)

        // Message-ID (recommended)
        buffer.append(contentsOf: [UInt8].messageIdPrefix)
        buffer.append(contentsOf: [UInt8](message.messageId))
        buffer.append(contentsOf: [UInt8].ascii.crlf)

        // Reply-To (optional)
        if let replyTo = message.replyTo {
            buffer.append(contentsOf: [UInt8].replyToPrefix)
            buffer.append(contentsOf: [UInt8](replyTo))
            buffer.append(contentsOf: [UInt8].ascii.crlf)
        }

        // MIME-Version (required for MIME messages)
        buffer.append(contentsOf: [UInt8].mimeVersionPrefix)
        buffer.append(utf8: message.mimeVersion)
        buffer.append(contentsOf: [UInt8].ascii.crlf)

        // Additional custom headers (in order)
        for header in message.additionalHeaders {
            buffer.append(contentsOf: [UInt8](header))
            buffer.append(contentsOf: [UInt8].ascii.crlf)
        }

        // Empty line separates headers from body
        buffer.append(contentsOf: [UInt8].ascii.crlf)

        // Body (as bytes)
        buffer.append(contentsOf: message.body)
    }

    /// Parses an RFC 5322 message from canonical byte representation (CANONICAL PRIMITIVE)
    ///
    /// **FUTURE TASK**: This is the canonical primitive parser for RFC 5322 messages.
    ///
    /// ## Complexity Note
    ///
    /// Message parsing is significantly more complex than component parsing because it must handle:
    /// - Header folding (CRLF + whitespace continuation)
    /// - Headers in arbitrary order
    /// - Optional and duplicate headers
    /// - Unknown/custom headers
    /// - MIME multi-part structure
    /// - Encoded-words in headers (=?charset?encoding?text?=)
    /// - Body transfer encodings (base64, quoted-printable)
    /// - Lenient parsing vs. strict validation
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (RFC 5322 formatted bytes)
    /// - **Codomain**: RFC_5322.Message (structured data)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [UInt8] (UTF-8 bytes) → Message
    /// ```
    ///
    /// ## Implementation Strategy
    ///
    /// When implemented, this parser should:
    /// 1. Split message into header section and body at first blank line (CRLF CRLF)
    /// 2. Parse headers with unfolding (handle CRLF + whitespace)
    /// 3. Extract required headers (From, To, Date, etc.)
    /// 4. Preserve additional headers in order
    /// 5. Handle MIME structure if present
    /// 6. Decode body based on Content-Transfer-Encoding
    ///
    /// ## Example (Future)
    ///
    /// ```swift
    /// let bytes = Array(emlFileContents.utf8)
    /// let message = try RFC_5322.Message(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of an RFC 5322 message
    /// - Throws: `RFC_5322.Message.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        // TODO: Implement RFC 5322 message parsing
        // This is a complex parser that must handle:
        // - Header/body separation
        // - Header unfolding
        // - Required header extraction (From, To, Date, Subject)
        // - Optional header handling (Cc, Bcc, Reply-To, Message-ID)
        // - MIME structure parsing
        // - Custom header preservation
        // - Various encoding schemes

        fatalError("RFC 5322 Message parsing not yet implemented")
    }
}

extension RFC_5322.Message: CustomStringConvertible {}
