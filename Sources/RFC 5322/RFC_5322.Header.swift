
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
        public let name: Header.Name

        /// The header field value
        public let value: String

        /// Creates a header field
        ///
        /// - Parameters:
        ///   - name: The header field name
        ///   - value: The header field value
        public init(name: Header.Name, value: String) {
            self.name = name
            self.value = value
        }
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
