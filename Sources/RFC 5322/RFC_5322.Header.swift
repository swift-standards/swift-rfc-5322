import INCITS_4_1986

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
        public let value: Header.Value

        /// Creates a header field
        ///
        /// - Parameters:
        ///   - name: The header field name
        ///   - value: The header field value
        public init(
            name: Header.Name,
            value: Header.Value
        ) {
            self.name = name
            self.value = value
        }
    }
}

// MARK: - Header Parsing

extension RFC_5322.Header: Binary.ASCII.Serializable {
    public static func serialize<Buffer>(ascii header: RFC_5322.Header, into buffer: inout Buffer)
    where Buffer: RangeReplaceableCollection, Buffer.Element == UInt8 {
        buffer.append(contentsOf: [UInt8](header.name))
        buffer.append(.ascii.colon)
        buffer.append(.ascii.space)
        buffer.append(contentsOf: [UInt8](header.value))
    }

    /// Parses a header from canonical byte representation (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 5322 headers are "Name: Value" format.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_5322.Header (structured data)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [UInt8] (UTF-8 bytes) → Header
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array("Content-Type: text/html".utf8)
    /// let header = try RFC_5322.Header(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the header
    /// - Throws: `RFC_5322.Header.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        // Split on first colon to separate name from value
        guard let colonIndex = bytes.firstIndex(of: .ascii.colon) else {
            let string = String(decoding: bytes, as: UTF8.self)
            throw Error.invalidFormat(string, reason: "Missing colon separator")
        }

        let nameBytes = bytes[..<colonIndex]
        let valueStartIndex = bytes.index(after: colonIndex)
        let valueBytes = bytes[valueStartIndex...]

        // Parse name and value through their byte-level initializers
        // Wrap their errors in Header.Error for typed throws
        let name: RFC_5322.Header.Name
        do {
            name = try RFC_5322.Header.Name(ascii: Array(nameBytes))
        } catch {
            throw Error.invalidName(error)
        }

        let value: RFC_5322.Header.Value
        do {
            value = try RFC_5322.Header.Value(ascii: Array(valueBytes))
        } catch {
            throw Error.invalidValue(error)
        }

        // Use memberwise initializer
        self.init(name: name, value: value)
    }
}

// MARK: - Header Protocol Conformances

extension RFC_5322.Header: CustomStringConvertible {}

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
            first(where: { $0.name == name })?.value.rawValue
        }
        set {
            removeAll(where: { $0.name == name })
            if let newValue = try? newValue.map({ try RFC_5322.Header.Value($0) }) {
                append(
                    RFC_5322.Header(
                        name: name,
                        value: newValue
                    )
                )
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
    public func values(for name: RFC_5322.Header.Name) -> [RFC_5322.Header.Value] {
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
    public init(dictionaryLiteral elements: (RFC_5322.Header.Name, RFC_5322.Header.Value)...) {
        self = elements.map { RFC_5322.Header(name: $0.0, value: $0.1) }
    }
}
