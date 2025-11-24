//
//  String.swift
//  swift-rfc-5322
//
//  Type conversions for RFC 5322 Message
//

import INCITS_4_1986
import RFC_1123

extension String {
    /// Creates RFC 5322 message string from a Message
    ///
    /// Convenience initializer that converts message to bytes then decodes as UTF-8.
    /// Use `[UInt8](message)` if you need the actual byte representation.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let message = RFC_5322.Message(...)
    /// let emlContent = String(message)
    /// ```
    public init(_ message: RFC_5322.Message) {
        let bytes = [UInt8](message)
        self = String(decoding: bytes, as: UTF8.self)
    }
}

extension String {
    public init(_ emailAddress: RFC_5322.EmailAddress) {
        if let name = emailAddress.displayName {
            // Quote the display name if it contains special characters or non-ASCII
            let needsQuoting = name.contains(where: {
                !$0.ascii.isLetter && !$0.ascii.isDigit && !$0.ascii.isWhitespace || $0.asciiValue == nil
            })
            let quotedName = needsQuoting ? "\"\(name)\"" : name
            self = "\(quotedName) <\(emailAddress.localPart)@\(emailAddress.domain.name)>"  // Exactly one space before angle bracket
        } else {
            self = "\(emailAddress.localPart)@\(emailAddress.domain.name)"
        }
    }
}

extension String {
    public init(_ date: RFC_5322.DateTime) {
        self = date.description
    }
}

extension StringProtocol {
    /// String representation of an RFC 5322 header
    ///
    /// Composes through canonical byte representation for academic correctness.
    ///
    /// ## Category Theory
    ///
    /// String display composes as:
    /// ```
    /// Header → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let header = RFC_5322.Header(name: .subject, value: "Hello")
    /// let rendered = String(header)  // "Subject: Hello"
    /// ```
    public init(_ header: RFC_5322.Header) {
        self = Self(decoding: [UInt8](header), as: UTF8.self)
    }
}

extension String {
    /// Creates string representation of RFC 5322 header value (STRING REPRESENTATION)
    ///
    /// Composes through canonical byte representation for academic correctness.
    ///
    /// ## Category Theory
    ///
    /// String display composes as:
    /// ```
    /// Header.Value → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let value = RFC_5322.Header.Value("text/html")
    /// let string = String(value)  // "text/html"
    /// ```
    public init(_ value: RFC_5322.Header.Value) {
        self = String(decoding: [UInt8](value), as: UTF8.self)
    }
}

extension String {
    /// Creates string representation of RFC 5322 header name (STRING REPRESENTATION)
    ///
    /// Composes through canonical byte representation for academic correctness.
    ///
    /// ## Category Theory
    ///
    /// String display composes as:
    /// ```
    /// Header.Name → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let name = RFC_5322.Header.Name.contentType
    /// let string = String(name)  // "Content-Type"
    /// ```
    public init(_ name: RFC_5322.Header.Name) {
        self = String(decoding: [UInt8](name), as: UTF8.self)
    }
}
