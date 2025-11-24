//
//  [UInt8].swift
//  swift-rfc-5322
//
//  Type conversions for RFC 5322 Message
//

import Standards
import StandardTime
import INCITS_4_1986
import RFC_1123

// MARK: - Constants

package extension [UInt8] {
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


// MARK: - Header.Name

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

// MARK: - Header.Value

extension [UInt8] {
    /// Creates ASCII byte representation of an RFC 5322 header value
    ///
    /// This is the canonical serialization of header values to bytes.
    /// RFC 5322 header values are ASCII with possible folding whitespace.
    ///
    /// ## Category Theory
    ///
    /// This is the most universal serialization (natural transformation):
    /// - **Domain**: RFC_5322.Header.Value (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// Header.Value → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let value = RFC_5322.Header.Value("text/html")
    /// let bytes = [UInt8](value)
    /// // bytes == "text/html" as ASCII bytes
    /// ```
    ///
    /// - Parameter value: The header value to serialize
    public init(_ value: RFC_5322.Header.Value) {
        self = Array(value.rawValue.utf8)
    }
}

// MARK: - Header



// MARK: - DateTime

