//
//  RFC_5322.Header.Name.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

public import INCITS_4_1986

extension RFC_5322.Header {
    /// Email header field name
    ///
    /// Represents header field names in Internet Message Format as defined by RFC 5322.
    /// Header field names are case-insensitive per the specification.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let from: Self = .from
    /// let custom: Self = .init(__unchecked: (), rawValue: "X-Custom-Header")
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
    public struct Name: Sendable, Codable {
        /// The header field name
        public let rawValue: String

        /// Creates a header name
        ///
        /// - Parameter rawValue: The header field name (case-insensitive)
        public init(
            __unchecked: (),
            rawValue: String
        ) {
            // Header names are case-insensitive, but we preserve original case
            // for display purposes while using case-insensitive comparison
            self.rawValue = rawValue
        }
    }
}

extension RFC_5322.Header.Name: Hashable {

    /// Hash value (case-insensitive)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.lowercased())
    }

    /// Equality comparison (case-insensitive)
    public static func == (lhs: RFC_5322.Header.Name, rhs: RFC_5322.Header.Name) -> Bool {
        lhs.rawValue.lowercased() == rhs.rawValue.lowercased()
    }

    /// Equality comparison (case-insensitive)
    public static func == (lhs: RFC_5322.Header.Name, rhs: Self.RawValue) -> Bool {
        lhs.rawValue.lowercased() == rhs.lowercased()
    }
}

extension RFC_5322.Header.Name: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init

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
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
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
                let reason =
                    byte == .ascii.colon
                    ? "Field name cannot contain colon"
                    : "Must be printable ASCII except colon"
                throw Error.invalidCharacter(string, byte: byte, reason: reason)
            }
        }

        self.init(__unchecked: (), rawValue: String(decoding: bytes, as: UTF8.self))
    }
}

extension [UInt8] {
    /// Creates ASCII byte representation of an RFC 5322 header name
    ///
    /// This is the canonical serialization of header names to bytes.
    /// RFC 5322 header names are ASCII-only by definition.
    ///
    /// ## Category Theory
    ///
    /// This is the most universal serialization (natural transformation):
    /// - **Domain**: RFC_5322.Header.Name (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// Header.Name → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let name = RFC_5322.Header.Name.contentType
    /// let bytes = [UInt8](name)
    /// // bytes == "Content-Type" as ASCII bytes
    /// ```
    ///
    /// - Parameter name: The header name to serialize
    public init(_ name: RFC_5322.Header.Name) {
        self = Array(name.rawValue.utf8)
    }
}

extension RFC_5322.Header.Name: UInt8.ASCII.RawRepresentable {}

extension RFC_5322.Header.Name: CustomStringConvertible {}

extension RFC_5322.Header.Name {
    /// From: header (originator)
    public static let from: Self = .init(__unchecked: (), rawValue: "From")

    /// To: header (primary recipients)
    public static let to: Self = .init(__unchecked: (), rawValue: "To")

    /// Cc: header (carbon copy recipients)
    public static let cc: Self = .init(__unchecked: (), rawValue: "Cc")

    /// Bcc: header (blind carbon copy recipients)
    public static let bcc: Self = .init(__unchecked: (), rawValue: "Bcc")

    /// Subject: header
    public static let subject: Self = .init(__unchecked: (), rawValue: "Subject")

    /// Date: header
    public static let date: Self = .init(__unchecked: (), rawValue: "Date")

    /// Message-ID: header (unique message identifier)
    public static let messageId: Self = .init(__unchecked: (), rawValue: "Message-ID")

    /// Reply-To: header
    public static let replyTo: Self = .init(__unchecked: (), rawValue: "Reply-To")

    /// Sender: header (actual sender if different from From)
    public static let sender: Self = .init(__unchecked: (), rawValue: "Sender")

    /// In-Reply-To: header (message being replied to)
    public static let inReplyTo: Self = .init(__unchecked: (), rawValue: "In-Reply-To")

    /// References: header (related messages)
    public static let references: Self = .init(__unchecked: (), rawValue: "References")

    /// Resent-From: header
    public static let resentFrom: Self = .init(__unchecked: (), rawValue: "Resent-From")

    /// Resent-To: header
    public static let resentTo: Self = .init(__unchecked: (), rawValue: "Resent-To")

    /// Resent-Date: header
    public static let resentDate: Self = .init(__unchecked: (), rawValue: "Resent-Date")

    /// Resent-Message-ID: header
    public static let resentMessageId: Self = .init(__unchecked: (), rawValue: "Resent-Message-ID")

    /// Return-Path: header
    public static let returnPath: Self = .init(__unchecked: (), rawValue: "Return-Path")

    /// Received: header (mail transfer path)
    public static let received: Self = .init(__unchecked: (), rawValue: "Received")
}

extension RFC_5322.Header.Name {
    /// X-Mailer: header (mail client identification)
    public static let xMailer: Self = .init(__unchecked: (), rawValue: "X-Mailer")

    /// X-Priority: header (message priority)
    public static let xPriority: Self = .init(__unchecked: (), rawValue: "X-Priority")

    /// List-Unsubscribe: header (mailing list unsubscribe)
    public static let listUnsubscribe: Self = .init(__unchecked: (), rawValue: "List-Unsubscribe")

    /// List-ID: header (mailing list identifier)
    public static let listId: Self = .init(__unchecked: (), rawValue: "List-ID")

    /// Precedence: header
    public static let precedence: Self = .init(__unchecked: (), rawValue: "Precedence")

    /// Auto-Submitted: header
    public static let autoSubmitted: Self = .init(__unchecked: (), rawValue: "Auto-Submitted")
}

extension RFC_5322.Header.Name {
    /// X-Apple-Base-Url: header
    public static let xAppleBaseUrl: Self = .init(__unchecked: (), rawValue: "X-Apple-Base-Url")

    /// X-Universally-Unique-Identifier: header
    public static let xUniversallyUniqueIdentifier: Self = .init(
        __unchecked: (),
        rawValue: "X-Universally-Unique-Identifier"
    )

    /// X-Apple-Mail-Remote-Attachments: header
    public static let xAppleMailRemoteAttachments: Self = .init(
        __unchecked: (),
        rawValue: "X-Apple-Mail-Remote-Attachments"
    )

    /// X-Apple-Windows-Friendly: header
    public static let xAppleWindowsFriendly: Self = .init(
        __unchecked: (),
        rawValue: "X-Apple-Windows-Friendly"
    )

    /// X-Apple-Mail-Signature: header
    public static let xAppleMailSignature: Self = .init(
        __unchecked: (),
        rawValue: "X-Apple-Mail-Signature"
    )

    /// X-Uniform-Type-Identifier: header
    public static let xUniformTypeIdentifier: Self = .init(
        __unchecked: (),
        rawValue: "X-Uniform-Type-Identifier"
    )
}
