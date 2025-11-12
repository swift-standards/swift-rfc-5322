import Foundation

extension RFC_5322 {
    /// Email header field (name-value pair)
    ///
    /// Represents a complete header field in Internet Message Format as defined by RFC 5322.
    /// Headers are stored as an ordered sequence of name-value pairs.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let header = RFC_5322.Header(name: .contentType, value: "text/html")
    ///
    /// var headers: [RFC_5322.Header] = [
    ///     .init(name: .from, value: "sender@example.com"),
    ///     .init(name: .to, value: "recipient@example.com")
    /// ]
    ///
    /// // Convenient subscript access
    /// headers[.contentType] = "text/html"
    /// print(headers[.contentType]) // Optional("text/html")
    /// ```
    ///
    /// ## RFC Reference
    ///
    /// From RFC 5322 Section 2.2:
    ///
    /// > Each header field is a line of characters with a name, a colon,
    /// > and a value. Field names are comprised of printable US-ASCII
    /// > characters except colon. Field names are case-insensitive.
    public struct Header: Hashable, Sendable, Codable {
        /// The header field name
        public let name: Name

        /// The header field value
        public let value: String

        /// Creates a header field
        ///
        /// - Parameters:
        ///   - name: The header field name
        ///   - value: The header field value
        public init(name: Name, value: String) {
            self.name = name
            self.value = value
        }
    }
}

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
    /// let from = RFC_5322.Header.Name.from
    /// let custom = RFC_5322.Header.Name("X-Custom-Header")
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

// MARK: - RFC 5322 Standard Headers

extension RFC_5322.Header.Name {
    /// From: header (originator)
    public static let from = RFC_5322.Header.Name("From")

    /// To: header (primary recipients)
    public static let to = RFC_5322.Header.Name("To")

    /// Cc: header (carbon copy recipients)
    public static let cc = RFC_5322.Header.Name("Cc")

    /// Bcc: header (blind carbon copy recipients)
    public static let bcc = RFC_5322.Header.Name("Bcc")

    /// Subject: header
    public static let subject = RFC_5322.Header.Name("Subject")

    /// Date: header
    public static let date = RFC_5322.Header.Name("Date")

    /// Message-ID: header (unique message identifier)
    public static let messageId = RFC_5322.Header.Name("Message-ID")

    /// Reply-To: header
    public static let replyTo = RFC_5322.Header.Name("Reply-To")

    /// Sender: header (actual sender if different from From)
    public static let sender = RFC_5322.Header.Name("Sender")

    /// In-Reply-To: header (message being replied to)
    public static let inReplyTo = RFC_5322.Header.Name("In-Reply-To")

    /// References: header (related messages)
    public static let references = RFC_5322.Header.Name("References")

    /// Resent-From: header
    public static let resentFrom = RFC_5322.Header.Name("Resent-From")

    /// Resent-To: header
    public static let resentTo = RFC_5322.Header.Name("Resent-To")

    /// Resent-Date: header
    public static let resentDate = RFC_5322.Header.Name("Resent-Date")

    /// Resent-Message-ID: header
    public static let resentMessageId = RFC_5322.Header.Name("Resent-Message-ID")

    /// Return-Path: header
    public static let returnPath = RFC_5322.Header.Name("Return-Path")

    /// Received: header (mail transfer path)
    public static let received = RFC_5322.Header.Name("Received")
}

// MARK: - MIME Headers (RFC 2045)

extension RFC_5322.Header.Name {
    /// Content-Type: header (media type)
    public static let contentType = RFC_5322.Header.Name("Content-Type")

    /// Content-Transfer-Encoding: header
    public static let contentTransferEncoding = RFC_5322.Header.Name("Content-Transfer-Encoding")

    /// MIME-Version: header
    public static let mimeVersion = RFC_5322.Header.Name("MIME-Version")

    /// Content-Disposition: header
    public static let contentDisposition = RFC_5322.Header.Name("Content-Disposition")

    /// Content-ID: header
    public static let contentId = RFC_5322.Header.Name("Content-ID")

    /// Content-Description: header
    public static let contentDescription = RFC_5322.Header.Name("Content-Description")
}

// MARK: - Common Extension Headers

extension RFC_5322.Header.Name {
    /// X-Mailer: header (mail client identification)
    public static let xMailer = RFC_5322.Header.Name("X-Mailer")

    /// X-Priority: header (message priority)
    public static let xPriority = RFC_5322.Header.Name("X-Priority")

    /// List-Unsubscribe: header (mailing list unsubscribe)
    public static let listUnsubscribe = RFC_5322.Header.Name("List-Unsubscribe")

    /// List-ID: header (mailing list identifier)
    public static let listId = RFC_5322.Header.Name("List-ID")

    /// Precedence: header
    public static let precedence = RFC_5322.Header.Name("Precedence")

    /// Auto-Submitted: header
    public static let autoSubmitted = RFC_5322.Header.Name("Auto-Submitted")
}

// MARK: - Apple Mail Headers

extension RFC_5322.Header.Name {
    /// X-Apple-Base-Url: header
    public static let xAppleBaseUrl = RFC_5322.Header.Name("X-Apple-Base-Url")

    /// X-Universally-Unique-Identifier: header
    public static let xUniversallyUniqueIdentifier = RFC_5322.Header.Name("X-Universally-Unique-Identifier")

    /// X-Apple-Mail-Remote-Attachments: header
    public static let xAppleMailRemoteAttachments = RFC_5322.Header.Name("X-Apple-Mail-Remote-Attachments")

    /// X-Apple-Windows-Friendly: header
    public static let xAppleWindowsFriendly = RFC_5322.Header.Name("X-Apple-Windows-Friendly")

    /// X-Apple-Mail-Signature: header
    public static let xAppleMailSignature = RFC_5322.Header.Name("X-Apple-Mail-Signature")

    /// X-Uniform-Type-Identifier: header
    public static let xUniformTypeIdentifier = RFC_5322.Header.Name("X-Uniform-Type-Identifier")
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

// MARK: - Header Protocol Conformances

extension RFC_5322.Header: CustomStringConvertible {
    /// Returns the header in RFC 5322 format (name: value)
    public var description: String {
        "\(name.rawValue): \(value)"
    }
}

// MARK: - Array Convenience Extensions

extension Array where Element == RFC_5322.Header {
    /// Subscript for convenient header access by name
    ///
    /// Returns the value of the first header with the given name.
    /// Setting a value removes all existing headers with that name and appends a new one.
    /// Setting nil removes all headers with that name.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var headers: [RFC_5322.Header] = []
    /// headers[.contentType] = "text/html"
    /// print(headers[.contentType]) // Optional("text/html")
    /// headers[.contentType] = nil  // Removes the header
    /// ```
    public subscript(name: RFC_5322.Header.Name) -> String? {
        get {
            first(where: { $0.name == name })?.value
        }
        set {
            removeAll(where: { $0.name == name })
            if let newValue = newValue {
                append(RFC_5322.Header(name: name, value: newValue))
            }
        }
    }

    /// Returns all headers with the given name
    ///
    /// Useful for headers that can appear multiple times (like Received).
    ///
    /// ## Example
    ///
    /// ```swift
    /// let received = headers.all(.received)
    /// ```
    public func all(_ name: RFC_5322.Header.Name) -> [RFC_5322.Header] {
        filter { $0.name == name }
    }

    /// Returns all values for headers with the given name
    ///
    /// ## Example
    ///
    /// ```swift
    /// let receivedValues = headers.values(for: .received)
    /// ```
    public func values(for name: RFC_5322.Header.Name) -> [String] {
        filter { $0.name == name }.map(\.value)
    }
}

extension Array: @retroactive ExpressibleByDictionaryLiteral where Element == RFC_5322.Header {
    /// Creates an array of headers from a dictionary literal
    ///
    /// Enables convenient syntax for creating headers.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let headers: [RFC_5322.Header] = [
    ///     .from: "sender@example.com",
    ///     .to: "recipient@example.com",
    ///     .subject: "Hello"
    /// ]
    /// ```
    public init(dictionaryLiteral elements: (RFC_5322.Header.Name, String)...) {
        self = elements.map { RFC_5322.Header(name: $0.0, value: $0.1) }
    }
}
