import Foundation

extension RFC_5322 {
    /// Email header field name
    ///
    /// Represents header field names in Internet Message Format as defined by RFC 5322.
    /// Header field names are case-insensitive per the specification.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let from = RFC_5322.HeaderName.from
    /// let custom = RFC_5322.HeaderName("X-Custom-Header")
    ///
    /// var headers: [RFC_5322.HeaderName: String] = [:]
    /// headers[.messageId] = "<abc@example.com>"
    /// headers[.contentType] = "text/plain"
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
    public struct HeaderName: Hashable, Sendable, Codable {
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
        public static func == (lhs: RFC_5322.HeaderName, rhs: RFC_5322.HeaderName) -> Bool {
            lhs.rawValue.lowercased() == rhs.rawValue.lowercased()
        }
    }
}

// MARK: - RFC 5322 Standard Headers

extension RFC_5322.HeaderName {
    /// From: header (originator)
    public static let from = RFC_5322.HeaderName("From")

    /// To: header (primary recipients)
    public static let to = RFC_5322.HeaderName("To")

    /// Cc: header (carbon copy recipients)
    public static let cc = RFC_5322.HeaderName("Cc")

    /// Bcc: header (blind carbon copy recipients)
    public static let bcc = RFC_5322.HeaderName("Bcc")

    /// Subject: header
    public static let subject = RFC_5322.HeaderName("Subject")

    /// Date: header
    public static let date = RFC_5322.HeaderName("Date")

    /// Message-ID: header (unique message identifier)
    public static let messageId = RFC_5322.HeaderName("Message-ID")

    /// Reply-To: header
    public static let replyTo = RFC_5322.HeaderName("Reply-To")

    /// Sender: header (actual sender if different from From)
    public static let sender = RFC_5322.HeaderName("Sender")

    /// In-Reply-To: header (message being replied to)
    public static let inReplyTo = RFC_5322.HeaderName("In-Reply-To")

    /// References: header (related messages)
    public static let references = RFC_5322.HeaderName("References")

    /// Resent-From: header
    public static let resentFrom = RFC_5322.HeaderName("Resent-From")

    /// Resent-To: header
    public static let resentTo = RFC_5322.HeaderName("Resent-To")

    /// Resent-Date: header
    public static let resentDate = RFC_5322.HeaderName("Resent-Date")

    /// Resent-Message-ID: header
    public static let resentMessageId = RFC_5322.HeaderName("Resent-Message-ID")

    /// Return-Path: header
    public static let returnPath = RFC_5322.HeaderName("Return-Path")

    /// Received: header (mail transfer path)
    public static let received = RFC_5322.HeaderName("Received")
}

// MARK: - MIME Headers (RFC 2045)

extension RFC_5322.HeaderName {
    /// Content-Type: header (media type)
    public static let contentType = RFC_5322.HeaderName("Content-Type")

    /// Content-Transfer-Encoding: header
    public static let contentTransferEncoding = RFC_5322.HeaderName("Content-Transfer-Encoding")

    /// MIME-Version: header
    public static let mimeVersion = RFC_5322.HeaderName("MIME-Version")

    /// Content-Disposition: header
    public static let contentDisposition = RFC_5322.HeaderName("Content-Disposition")

    /// Content-ID: header
    public static let contentId = RFC_5322.HeaderName("Content-ID")

    /// Content-Description: header
    public static let contentDescription = RFC_5322.HeaderName("Content-Description")
}

// MARK: - Common Extension Headers

extension RFC_5322.HeaderName {
    /// X-Mailer: header (mail client identification)
    public static let xMailer = RFC_5322.HeaderName("X-Mailer")

    /// X-Priority: header (message priority)
    public static let xPriority = RFC_5322.HeaderName("X-Priority")

    /// List-Unsubscribe: header (mailing list unsubscribe)
    public static let listUnsubscribe = RFC_5322.HeaderName("List-Unsubscribe")

    /// List-ID: header (mailing list identifier)
    public static let listId = RFC_5322.HeaderName("List-ID")

    /// Precedence: header
    public static let precedence = RFC_5322.HeaderName("Precedence")

    /// Auto-Submitted: header
    public static let autoSubmitted = RFC_5322.HeaderName("Auto-Submitted")
}

// MARK: - Apple Mail Headers

extension RFC_5322.HeaderName {
    /// X-Apple-Base-Url: header
    public static let xAppleBaseUrl = RFC_5322.HeaderName("X-Apple-Base-Url")

    /// X-Universally-Unique-Identifier: header
    public static let xUniversallyUniqueIdentifier = RFC_5322.HeaderName("X-Universally-Unique-Identifier")

    /// X-Apple-Mail-Remote-Attachments: header
    public static let xAppleMailRemoteAttachments = RFC_5322.HeaderName("X-Apple-Mail-Remote-Attachments")

    /// X-Apple-Windows-Friendly: header
    public static let xAppleWindowsFriendly = RFC_5322.HeaderName("X-Apple-Windows-Friendly")

    /// X-Apple-Mail-Signature: header
    public static let xAppleMailSignature = RFC_5322.HeaderName("X-Apple-Mail-Signature")

    /// X-Uniform-Type-Identifier: header
    public static let xUniformTypeIdentifier = RFC_5322.HeaderName("X-Uniform-Type-Identifier")
}

// MARK: - Protocol Conformances

extension RFC_5322.HeaderName: ExpressibleByStringLiteral {
    /// Creates a header name from a string literal
    ///
    /// Allows convenient syntax: `let header: HeaderName = "X-Custom"`
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension RFC_5322.HeaderName: CustomStringConvertible {
    /// Returns the header field name
    public var description: String {
        rawValue
    }
}
