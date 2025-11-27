//
//  RFC_5322.Header.Value.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

public import INCITS_4_1986

extension RFC_5322.Header {
    public struct Value: Sendable, Hashable, Codable {
        public let rawValue: String
        
        init(
            __unchecked: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

extension RFC_5322.Header.Value  {
    /// Equality comparison (case-sensitive)
    public static func == (lhs: RFC_5322.Header.Value, rhs: RFC_5322.Header.Value) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    /// Equality comparison with raw value (case-sensitive)
    public static func == (lhs: RFC_5322.Header.Value, rhs: Self.RawValue) -> Bool {
        lhs.rawValue == rhs
    }
}

extension RFC_5322.Header.Value: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (Self) -> [UInt8] = [UInt8].init
    
    /// Parses a header value from canonical byte representation (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// Implements RFC 5322 folding whitespace unfolding and character validation.
    ///
    /// ## RFC 5322 Compliance
    ///
    /// Per RFC 5322 Section 2.2:
    /// - Field bodies may contain printable US-ASCII (0x20-0x7E) and HTAB (0x09)
    /// - CR and LF are only allowed in CRLF folding sequences
    /// - Unfolding removes any CRLF immediately followed by WSP (space or tab)
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes with possible folding)
    /// - **Codomain**: RFC_5322.Header.Value (unfolded, validated)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [UInt8] (UTF-8 bytes) → Header.Value
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Simple value
    /// let bytes = Array("text/html; charset=UTF-8".utf8)
    /// let value = try RFC_5322.Header.Value(ascii: bytes)
    ///
    /// // Folded value (CRLF followed by space)
    /// let folded = Array("text/html;\r\n charset=UTF-8".utf8)
    /// let unfolded = try RFC_5322.Header.Value(ascii: folded)
    /// // Result: "text/html; charset=UTF-8" (CRLF removed)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the header value
    /// - Throws: `RFC_5322.Header.Value.Error` if the bytes contain invalid characters or improper folding
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        // RFC 5322 Section 2.2.3: Unfolding
        // "Unfolding is accomplished by simply removing any CRLF
        // that is immediately followed by WSP"

        // Step 1: Unfold and validate folding patterns using Collection index traversal
        var unfolded = [UInt8]()
        var index = bytes.startIndex

        while index != bytes.endIndex {
            let byte = bytes[index]

            // Check for CR
            if byte == .ascii.cr {
                let nextIndex = bytes.index(after: index)
                // Must be followed by LF (CRLF sequence)
                guard nextIndex != bytes.endIndex, bytes[nextIndex] == .ascii.lf else {
                    let string = String(decoding: bytes, as: UTF8.self)
                    throw Error.invalidCharacter(string, byte: byte, reason: "CR must be followed by LF")
                }

                let afterLFIndex = bytes.index(after: nextIndex)
                // CRLF found - check if it's followed by WSP (folding)
                if afterLFIndex != bytes.endIndex,
                   (bytes[afterLFIndex] == .ascii.sp || bytes[afterLFIndex] == .ascii.htab) {
                    // Valid folding: skip CRLF, keep the WSP
                    index = afterLFIndex  // Move to WSP, will be added in next iteration
                } else {
                    // CRLF not followed by WSP - invalid
                    let string = String(decoding: bytes, as: UTF8.self)
                    throw Error.invalidFolding(string, byte: byte, reason: "CRLF must be followed by WSP (space or tab) for folding")
                }
            } else if byte == .ascii.lf {
                // LF without CR - invalid
                let string = String(decoding: bytes, as: UTF8.self)
                throw Error.invalidCharacter(string, byte: byte, reason: "LF must be preceded by CR")
            } else {
                unfolded.append(byte)
                index = bytes.index(after: index)
            }
        }

        // Step 2: Strip leading OWS (optional whitespace)
        // RFC 5322 Section 3.2.2: The space after the colon is formatting, not semantic content
        // OWS = *(SP / HTAB)
        let trimmed = Array(unfolded.drop(while: { $0 == .ascii.sp || $0 == .ascii.htab }))

        // Step 3: Validate characters in trimmed value
        // RFC 5322 Section 2.2: Field body "may be composed of printable
        // US-ASCII characters as well as the space (SP, ASCII value 32)
        // and horizontal tab (HTAB, ASCII value 9) characters"
        for byte in trimmed {
            // Valid: printable ASCII (0x20-0x7E) OR HTAB (0x09)
            let valid = byte.ascii.isPrintable || byte == .ascii.htab

            guard valid else {
                let string = String(decoding: trimmed, as: UTF8.self)
                let reason: String
                if byte.ascii.isControl {
                    reason = "Control characters not allowed (except HTAB)"
                } else {
                    reason = "Must be printable ASCII or HTAB"
                }
                throw Error.invalidCharacter(string, byte: byte, reason: reason)
            }
        }

        self.init(
            __unchecked: (),
            rawValue: String(decoding: trimmed, as: UTF8.self)
        )
    }
}

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

extension RFC_5322.Header.Value: UInt8.ASCII.RawRepresentable {}

extension RFC_5322.Header.Value: CustomStringConvertible {}

extension RFC_5322.Header.Value: ExpressibleByIntegerLiteral {
    /// Creates a header value from an integer literal
    ///
    /// **Warning**: Bypasses validation via `init(unchecked:)`.
    /// Only use with known-valid compile-time constants.
    ///
    /// Convenient for numeric headers:
    /// ```swift
    /// let contentLength: Header.Value = 1234
    /// let maxForwards: Header.Value = 70
    /// ```
    public init(integerLiteral value: Int) {
        self.init(
            __unchecked: (),
            rawValue: String(value)
        )
    }
}

extension RFC_5322.Header.Value: ExpressibleByFloatLiteral {
    /// Creates a header value from a float literal
    ///
    /// **Warning**: Bypasses validation via `init(unchecked:)`.
    /// Only use with known-valid compile-time constants.
    ///
    /// Convenient for quality values:
    /// ```swift
    /// let quality: Header.Value = 0.8
    /// ```
    public init(floatLiteral value: Double) {
        self.init(
            __unchecked: (),
            rawValue: String(value)
        )
    }
}
