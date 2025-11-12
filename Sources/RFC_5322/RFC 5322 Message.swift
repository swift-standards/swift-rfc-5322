//
//  RFC 5322 Message.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 12/11/2025.
//

import Foundation
import RFC_1123

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
    public struct Message: Hashable, Sendable {
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
        public let date: Foundation.Date

        /// Unique message identifier
        public let messageId: String

        /// Message body as Data (typically MIME content from RFC 2045/2046)
        public let body: Data

        /// Additional custom headers
        public let additionalHeaders: [String: String]

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
        ///   - body: Message body as Data
        ///   - additionalHeaders: Additional custom headers
        ///   - mimeVersion: MIME-Version header (defaults to "1.0")
        public init(
            from: EmailAddress,
            to: [EmailAddress],
            cc: [EmailAddress]? = nil,
            bcc: [EmailAddress]? = nil,
            replyTo: EmailAddress? = nil,
            subject: String,
            date: Foundation.Date,
            messageId: String,
            body: Data,
            additionalHeaders: [String: String] = [:],
            mimeVersion: String = "1.0"
        ) {
            self.from = from
            self.to = to
            self.cc = cc
            self.bcc = bcc
            self.replyTo = replyTo
            self.subject = subject
            self.date = date
            self.messageId = messageId
            self.body = body
            self.additionalHeaders = additionalHeaders
            self.mimeVersion = mimeVersion
        }

        /// Generates a unique Message-ID
        ///
        /// Format: `<UUID@domain>` where domain is extracted from the from address
        public static func generateMessageId(from: EmailAddress) -> String {
            let uuid = UUID().uuidString
            let domain = from.domain.name
            return "<\(uuid)@\(domain)>"
        }

        /// Convenience property to get body as String
        ///
        /// Returns nil if body data is not valid UTF-8
        public var bodyString: String? {
            String(data: body, encoding: .utf8)
        }

        /// Renders the complete RFC 5322 message
        ///
        /// Generates headers and body in RFC 5322 format suitable for .eml files.
        /// BCC recipients are excluded from the rendered output per RFC 5322.
        ///
        /// - Returns: Complete RFC 5322 formatted message
        public func render() -> String {
            var lines: [String] = []

            // Required headers in recommended order (RFC 5322 Section 3.6)

            // From (required)
            lines.append("From: \(from.stringValue)")

            // To (required)
            let toAddresses = to.map(\.stringValue).joined(separator: ", ")
            lines.append("To: \(toAddresses)")

            // Cc (optional)
            if let cc = cc, !cc.isEmpty {
                let ccAddresses = cc.map(\.stringValue).joined(separator: ", ")
                lines.append("Cc: \(ccAddresses)")
            }

            // Subject (required in practice)
            lines.append("Subject: \(subject)")

            // Date (required)
            lines.append("Date: \(RFC_5322.Date.string(from: date))")

            // Message-ID (recommended)
            lines.append("Message-ID: \(messageId)")

            // Reply-To (optional)
            if let replyTo = replyTo {
                lines.append("Reply-To: \(replyTo.stringValue)")
            }

            // MIME-Version (required for MIME messages)
            lines.append("MIME-Version: \(mimeVersion)")

            // Additional custom headers (sorted for consistency)
            for (key, value) in additionalHeaders.sorted(by: { $0.key < $1.key }) {
                lines.append("\(key): \(value)")
            }

            // Empty line separates headers from body
            lines.append("")

            // Body (convert Data to String)
            if let bodyStr = String(data: body, encoding: .utf8) {
                lines.append(bodyStr)
            }

            return lines.joined(separator: "\r\n")
        }
    }
}
