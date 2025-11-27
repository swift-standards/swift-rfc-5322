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
    public struct LocalPart: Hashable, Sendable {
        package let storage: Storage
    }
}

extension RFC_5322.EmailAddress.LocalPart {
    // swiftlint:disable:next nesting
    package enum Storage: Hashable {
        case dotAtom([UInt8])  // Regular unquoted format (ASCII bytes)
        case quoted([UInt8])   // Quoted string format (ASCII bytes)
    }
}

extension RFC_5322.EmailAddress.LocalPart: UInt8.ASCII.Serializable {
    public static let serialize: @Sendable (RFC_5322.EmailAddress.LocalPart) -> [UInt8] = [UInt8].init
    
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
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        // Track first/last bytes and count via single iteration
        var firstByte: UInt8?
        var lastByte: UInt8?
        var count = 0

        for byte in bytes {
            if firstByte == nil { firstByte = byte }
            lastByte = byte
            count += 1
        }

        // Check overall length first
        guard count <= RFC_5322.EmailAddress.Limits.maxLength else {
            throw Error.tooLong(count)
        }

        guard let first = firstByte, let last = lastByte else {
            throw Error.invalidDotAtom  // Empty local-part is invalid
        }

        // Handle quoted string format: starts and ends with quotation mark
        if first == .ascii.quotationMark && last == .ascii.quotationMark && count >= 2 {
            // Validate quoted-string content at byte level
            // quoted-string = [^"\\\r\n] or \\["\]
            var skipNext = false
            var isFirst = true
            var byteCount = 0

            for byte in bytes {
                byteCount += 1
                // Skip first and last quotes
                if isFirst { isFirst = false; continue }
                if byteCount == count { continue }

                if skipNext {
                    skipNext = false
                    continue
                }

                if byte == .ascii.backslash {
                    // Mark to skip next character (escape sequence)
                    skipNext = true
                } else if byte == .ascii.quotationMark || byte == .ascii.cr || byte == .ascii.lf {
                    // Unescaped quote, CR, or LF not allowed
                    throw Error.invalidQuotedString
                }
            }

            // If we ended with backslash expecting next char, that's invalid
            if skipNext {
                throw Error.invalidQuotedString
            }

            self.storage = .quoted(Array(bytes))
        }
        // Handle dot-atom format
        else {
            // Check for leading/trailing dots
            guard first != .ascii.period && last != .ascii.period else {
                throw Error.leadingOrTrailingDot
            }

            // Validate dot-atom characters and check for consecutive dots
            var previousByte: UInt8?
            for byte in bytes {
                // Check for consecutive dots
                if byte == .ascii.period && previousByte == .ascii.period {
                    throw Error.consecutiveDots
                }
                previousByte = byte

                // Validate character
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
}

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

extension RFC_5322.EmailAddress.LocalPart: CustomStringConvertible {}
