//
//  [UInt8].swift
//  swift-rfc-5322
//
//  Type conversions for RFC 5322 Message
//

import Standards
import INCITS_4_1986

// MARK: - Constants

private extension [UInt8] {
    static let fromPrefix: [UInt8] = .init(utf8: "From: ")
    static let toPrefix: [UInt8] = .init(utf8: "To: ")
    static let ccPrefix: [UInt8] = .init(utf8: "Cc: ")
    static let subjectPrefix: [UInt8] = .init(utf8: "Subject: ")
    static let datePrefix: [UInt8] = .init(utf8: "Date: ")
    static let messageIdPrefix: [UInt8] = .init(utf8: "Message-ID: ")
    static let replyToPrefix: [UInt8] = .init(utf8: "Reply-To: ")
    static let mimeVersionPrefix: [UInt8] = .init(utf8: "MIME-Version: ")
    static let comma: [UInt8] = .init(utf8: ", ")
}



// MARK: - EmailAddress

extension [UInt8] {
    /// Creates RFC 5322 formatted email address bytes
    /// Direct byte-level construction without intermediate String allocation
    public init(_ emailAddress: RFC_5322.EmailAddress) {
        var result = [UInt8]()

        if let displayName = emailAddress.displayName {
            // Check if quoting is needed
            let needsQuoting = displayName.contains(where: {
                !$0.isLetter && !$0.isNumber && !$0.isWhitespace || $0.asciiValue == nil
            })

            if needsQuoting {
                result.append(.dquote)
                result.append(utf8: displayName)
                result.append(.dquote)
            } else {
                result.append(utf8: displayName)
            }

            result.append(.space)
            result.append(.lt)
            result.append(utf8: emailAddress.localPart.description)
            result.append(.at)
            result.append(utf8: emailAddress.domain.name)
            result.append(.gt)
        } else {
            result.append(utf8: emailAddress.localPart.description)
            result.append(.at)
            result.append(utf8: emailAddress.domain.name)
        }

        self = result
    }
}

// MARK: - Header

extension [UInt8] {
    /// Creates RFC 5322 formatted header bytes
    /// Direct byte-level construction without string interpolation
    public init(_ header: RFC_5322.Header) {
        var result = [UInt8]()
        result.append(utf8: header.name.rawValue)
        result.append(.colon)
        result.append(.space)
        result.append(utf8: header.value)
        self = result
    }
}

// MARK: - DateTime

extension [UInt8] {
    /// Creates RFC 5322 formatted date-time bytes
    public init(_ dateTime: RFC_5322.DateTime) {
        self = Array(dateTime.description.utf8)
    }
}

// MARK: - Message

extension [UInt8] {
    /// Creates RFC 5322 message bytes from a Message
    ///
    /// Generates headers and body in RFC 5322 format suitable for .eml files
    /// or SMTP transmission. BCC recipients are excluded from the output per RFC 5322.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let message = RFC_5322.Message(...)
    /// let bytes = [UInt8](message)
    /// ```
    public init(_ message: RFC_5322.Message) {
        // Pre-allocate capacity to avoid reallocations
        // Rough estimate: headers (~500 bytes) + body
        var result = [UInt8]()
        result.reserveCapacity(500 + message.body.count)

        // Required headers in recommended order (RFC 5322 Section 3.6)

        // From (required)
        result.append(contentsOf: [UInt8].fromPrefix)
        result.append(contentsOf: [UInt8](message.from))
        result.append(contentsOf: [UInt8].crlf)

        // To (required)
        result.append(contentsOf: [UInt8].toPrefix)
        var first = true
        for address in message.to {
            if !first { result.append(contentsOf: [UInt8].comma) }
            first = false
            result.append(contentsOf: [UInt8](address))
        }
        result.append(contentsOf: [UInt8].crlf)

        // Cc (optional)
        if let cc = message.cc, !cc.isEmpty {
            result.append(contentsOf: [UInt8].ccPrefix)
            first = true
            for address in cc {
                if !first { result.append(contentsOf: [UInt8].comma) }
                first = false
                result.append(contentsOf: [UInt8](address))
            }
            result.append(contentsOf: [UInt8].crlf)
        }

        // Subject (required in practice)
        result.append(contentsOf: [UInt8].subjectPrefix)
        result.append(utf8: message.subject)
        result.append(contentsOf: [UInt8].crlf)

        // Date (required)
        result.append(contentsOf: [UInt8].datePrefix)
        result.append(contentsOf: [UInt8](message.date))
        result.append(contentsOf: [UInt8].crlf)

        // Message-ID (recommended)
        result.append(contentsOf: [UInt8].messageIdPrefix)
        result.append(utf8: message.messageId)
        result.append(contentsOf: [UInt8].crlf)

        // Reply-To (optional)
        if let replyTo = message.replyTo {
            result.append(contentsOf: [UInt8].replyToPrefix)
            result.append(contentsOf: [UInt8](replyTo))
            result.append(contentsOf: [UInt8].crlf)
        }

        // MIME-Version (required for MIME messages)
        result.append(contentsOf: [UInt8].mimeVersionPrefix)
        result.append(utf8: message.mimeVersion)
        result.append(contentsOf: [UInt8].crlf)

        // Additional custom headers (in order)
        for header in message.additionalHeaders {
            result.append(contentsOf: [UInt8](header))
            result.append(contentsOf: [UInt8].crlf)
        }

        // Empty line separates headers from body
        result.append(contentsOf: [UInt8].crlf)

        // Body (as bytes)
        result.append(contentsOf: message.body)

        self = result
    }
}
