//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 24/11/2025.
//

import INCITS_4_1986

// MARK: - Local Part
extension RFC_5322.EmailAddress {
    /// RFC 5322 compliant local-part
    public struct LocalPart: Hashable, Sendable, CustomStringConvertible {
        package let storage: Storage

        /// Parses a local-part from canonical byte representation (CANONICAL PRIMITIVE)
        ///
        /// This is the primitive parser that works at the byte level.
        /// RFC 5322 local-parts are ASCII-only.
        ///
        /// ## Category Theory
        ///
        /// This is the fundamental parsing transformation:
        /// - **Domain**: [UInt8] (ASCII bytes)
        /// - **Codomain**: RFC_5322.EmailAddress.LocalPart (structured data)
        ///
        /// String-based parsing is derived as composition:
        /// ```
        /// String → [UInt8] (UTF-8 bytes) → LocalPart
        /// ```
        ///
        /// ## Example
        ///
        /// ```swift
        /// let bytes = Array("user".utf8)
        /// let localPart = try RFC_5322.EmailAddress.LocalPart(ascii: bytes)
        /// ```
        ///
        /// - Parameter bytes: The ASCII byte representation of the local-part
        /// - Throws: `RFC_5322.EmailAddress.LocalPart.Error` if the bytes are malformed
        public init(ascii bytes: [UInt8]) throws(Error) {
            // Check overall length first
            guard bytes.count <= Limits.maxLength else {
                throw Error.tooLong(bytes.count)
            }

            // Handle quoted string format: starts and ends with quotation mark
            if bytes.first == .ascii.quotationMark && bytes.last == .ascii.quotationMark {
                // Remove surrounding quotes for validation
                let contentBytes = bytes.dropFirst().dropLast()

                // Validate quoted-string content at byte level
                // quoted-string = [^"\\\r\n] or \\["\]
                for (index, byte) in contentBytes.enumerated() {
                    if byte == .ascii.backslash {
                        // Next character must be quote or backslash
                        guard index + 1 < contentBytes.count else {
                            throw Error.invalidQuotedString
                        }
                        let nextByte: UInt8 = contentBytes[contentBytes.index(contentBytes.startIndex, offsetBy: index + 1)]
                        guard nextByte == .ascii.quotationMark || nextByte == .ascii.backslash else {
                            throw Error.invalidQuotedString
                        }
                    } else if byte == .ascii.quotationMark || byte == .ascii.cr || byte == .ascii.lf {
                        // Unescaped quote, CR, or LF not allowed
                        throw Error.invalidQuotedString
                    }
                }

                self.storage = .quoted(Array(bytes))
            }
            // Handle dot-atom format
            else {
                // Check for consecutive dots
                for i in 0..<(bytes.count - 1) {
                    if bytes[i] == .ascii.period && bytes[i + 1] == .ascii.period {
                        throw Error.consecutiveDots
                    }
                }

                // Check for leading/trailing dots
                guard bytes.first != .ascii.period && bytes.last != .ascii.period else {
                    throw Error.leadingOrTrailingDot
                }

                // Validate dot-atom characters at byte level
                // atext = ALPHA / DIGIT / special characters
                for byte in bytes {
                    let isValid = byte.ascii.isLetter ||
                                  byte.ascii.isDigit ||
                                  byte == .ascii.period ||
                                  "!#$%&'*+-/=?^_`{|}~".utf8.contains(byte)
                    guard isValid else {
                        throw Error.invalidDotAtom
                    }
                }

                self.storage = .dotAtom(Array(bytes))
            }
        }

        /// Initialize with a string
        ///
        /// Composes through canonical byte representation for academic correctness.
        ///
        /// ## Category Theory
        ///
        /// Parsing composes as:
        /// ```
        /// String → [UInt8] (UTF-8) → LocalPart
        /// ```
        ///
        /// - Parameter string: The string representation of the local-part
        /// - Throws: `RFC_5322.EmailAddress.LocalPart.Error` if invalid
        public init(_ string: some StringProtocol) throws(Error) {
            // Convert to canonical byte representation (UTF-8, which is ASCII-compatible)
            let bytes = Array(string.utf8)

            // Delegate to primitive byte-level parser
            try self.init(ascii: bytes)
        }

        /// The string representation
        ///
        /// Composes through canonical byte representation for academic correctness.
        ///
        /// ## Category Theory
        ///
        /// String display composes as:
        /// ```
        /// LocalPart → [UInt8] → String (UTF-8)
        /// ```
        public var description: String {
            String(decoding: [UInt8](self), as: UTF8.self)
        }

        // swiftlint:disable:next nesting
        package enum Storage: Hashable {
            case dotAtom([UInt8])  // Regular unquoted format (ASCII bytes)
            case quoted([UInt8])   // Quoted string format (ASCII bytes)
        }
    }
}

// MARK: - Byte Serialization

extension [UInt8] {
    /// Creates ASCII byte representation of an RFC 5322 local-part
    ///
    /// This is the canonical serialization of local-parts to bytes.
    /// RFC 5322 local-parts are ASCII-only by definition.
    ///
    /// ## Category Theory
    ///
    /// This is the most universal serialization (natural transformation):
    /// - **Domain**: RFC_5322.EmailAddress.LocalPart (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// LocalPart → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ## Performance
    ///
    /// Zero-cost: Returns internal canonical byte storage directly.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let localPart = try RFC_5322.EmailAddress.LocalPart("user")
    /// let bytes = [UInt8](localPart)
    /// // bytes == "user" as ASCII bytes
    /// ```
    ///
    /// - Parameter localPart: The local-part to serialize
    public init(_ localPart: RFC_5322.EmailAddress.LocalPart) {
        // Zero-cost: direct access to canonical byte storage
        switch localPart.storage {
        case .dotAtom(let bytes), .quoted(let bytes):
            self = bytes
        }
    }
}

extension StringProtocol {
    /// String representation of an RFC 5322 local-part
    ///
    /// Composes through canonical byte representation for academic correctness.
    ///
    /// ## Category Theory
    ///
    /// String display composes as:
    /// ```
    /// LocalPart → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    public init(_ localPart: RFC_5322.EmailAddress.LocalPart) {
        self = Self(decoding: [UInt8](localPart), as: UTF8.self)
    }
}
