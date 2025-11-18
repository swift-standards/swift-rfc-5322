//
//  String.swift
//  swift-rfc-5322
//
//  Type conversions for RFC 5322 Message
//

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
                !$0.isLetter && !$0.isNumber && !$0.isWhitespace || $0.asciiValue == nil
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

extension String {
    public init(_ header: RFC_5322.Header) {
        self = "\(header.name.rawValue): \(header.value)"
    }
}
