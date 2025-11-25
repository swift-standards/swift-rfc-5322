//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 18/11/2025.
//

import INCITS_4_1986
public import RFC_1123

extension RFC_5322 {
    /// RFC 5322 compliant email address (Internet Message Format)
    public struct EmailAddress: Hashable, Sendable {
        /// The display name, if present
        public let displayName: String?
        
        /// The local part (before @)
        public let localPart: LocalPart
        
        /// The domain part (after @)
        public let domain: RFC_1123.Domain
        
        /// Initialize with components
        public init(
            displayName: String? = nil,
            localPart: LocalPart,
            domain: RFC_1123.Domain
        ) {
            self.displayName = displayName.map { String($0.trimming(.ascii.whitespaces)) }
            self.localPart = localPart
            self.domain = domain
        }
    }
}


extension RFC_5322.EmailAddress: UInt8.ASCII.Serializing {
    public static let serialize: @Sendable (RFC_5322.EmailAddress) -> [UInt8] = [UInt8].init
    
    /// Parses email address from canonical byte representation (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 5322 email addresses are ASCII-only.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_5322.EmailAddress (structured data)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [UInt8] (UTF-8 bytes) → EmailAddress
    /// ```
    ///
    /// ## Formats
    ///
    /// - Simple: `user@example.com`
    /// - With display name: `John Doe <user@example.com>`
    /// - With quoted display name: `"John Doe" <user@example.com>`
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array("user@example.com".utf8)
    /// let email = try RFC_5322.EmailAddress(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the email address
    /// - Throws: `RFC_5322.EmailAddress.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        // Delegate to concrete [UInt8] implementation to work around Swift compiler bug
        // (LinearLifetimeChecker crash with complex generic index types)
        try self.init(ascii: Array(bytes), in: ())
    }

    /// Internal initializer for concrete byte array (avoids compiler crash)
    internal init(ascii bytes: [UInt8], in context: Void) throws(Error) {
        // Find angle bracket positions
        var ltOffset: Int?
        var gtOffset: Int?

        for (i, byte) in bytes.enumerated() {
            if byte == .ascii.lt && ltOffset == nil {
                ltOffset = i
            }
            if byte == .ascii.gt {
                gtOffset = i
            }
        }

        // Look for angle brackets to determine format
        if let ltOff = ltOffset, let gtOff = gtOffset, ltOff < gtOff {
            // Format: "Display Name <local@domain>"
            let displayNameBytes = bytes[..<ltOff]
            let emailBytes = bytes[(ltOff + 1)..<gtOff]

            // Parse display name (trim whitespace)
            let displayName: String?
            if !displayNameBytes.isEmpty {
                var trimmedBytes = [UInt8]()
                var foundNonWhitespace = false
                var trailingWhitespace = [UInt8]()

                for byte in displayNameBytes {
                    if byte == .ascii.space || byte == .ascii.htab {
                        if foundNonWhitespace {
                            trailingWhitespace.append(byte)
                        }
                    } else {
                        foundNonWhitespace = true
                        trimmedBytes.append(contentsOf: trailingWhitespace)
                        trailingWhitespace.removeAll()
                        trimmedBytes.append(byte)
                    }
                }

                if !trimmedBytes.isEmpty {
                    var nameString = String(decoding: trimmedBytes, as: UTF8.self)

                    // Handle quoted display names: "Name" -> Name
                    if nameString.hasPrefix("\"") && nameString.hasSuffix("\"") {
                        nameString = String(nameString.dropFirst().dropLast())
                        nameString = nameString.replacing(#"\""#, with: "\"")
                            .replacing(#"\\"#, with: "\\")
                    }

                    displayName = nameString
                } else {
                    displayName = nil
                }
            } else {
                displayName = nil
            }

            // Parse email part (local@domain)
            guard let atIdx = emailBytes.firstIndex(of: .ascii.at) else {
                throw Error.missingAtSign
            }

            let localBytes = Array(emailBytes[..<atIdx])
            let domainBytes = Array(emailBytes[(atIdx + 1)...])

            // Parse components
            let localPartValue = try Self.parseLocalPart(localBytes)
            let domainValue = try Self.parseDomain(domainBytes)

            self.init(displayName: displayName, localPart: localPartValue, domain: domainValue)
        } else {
            // Simple format: local@domain
            guard let atIdx = bytes.firstIndex(of: .ascii.at) else {
                throw Error.missingAtSign
            }

            let localBytes = Array(bytes[..<atIdx])
            let domainBytes = Array(bytes[(atIdx + 1)...])

            // Parse components
            let localPartValue = try Self.parseLocalPart(localBytes)
            let domainValue = try Self.parseDomain(domainBytes)

            self.init(displayName: nil, localPart: localPartValue, domain: domainValue)
        }
    }

    /// Helper to parse local part with error wrapping (avoids compiler bug)
    private static func parseLocalPart(_ bytes: [UInt8]) throws(Error) -> LocalPart {
        do {
            return try LocalPart(ascii: bytes)
        } catch {
            throw Error.localPart(error)
        }
    }

    /// Helper to parse domain with error wrapping (avoids compiler bug)
    private static func parseDomain(_ bytes: [UInt8]) throws(Error) -> RFC_1123.Domain {
        do {
            return try RFC_1123.Domain(ascii: bytes)
        } catch {
            throw Error.domain(error)
        }
    }
}

extension [UInt8] {
    /// Creates RFC 5322 formatted email address bytes (CANONICAL SERIALIZATION)
    ///
    /// This is the canonical byte-level serialization of RFC 5322 email addresses.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental serialization transformation:
    /// - **Domain**: RFC_5322.EmailAddress (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// EmailAddress → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ## Format
    ///
    /// Produces RFC 5322 email address format:
    /// - Simple: `user@example.com`
    /// - With display name: `John Doe <user@example.com>`
    /// - With quoted display name: `"John Doe" <user@example.com>`
    ///
    /// ## Example
    ///
    /// ```swift
    /// let email = RFC_5322.EmailAddress(displayName: "John", localPart: ..., domain: ...)
    /// let bytes = [UInt8](email)
    /// // bytes == "John <user@example.com>" as ASCII bytes
    /// ```
    ///
    /// - Parameter emailAddress: The email address to serialize
    public init(_ emailAddress: RFC_5322.EmailAddress) {
        var result = [UInt8]()

        if let displayName = emailAddress.displayName {
            // Check if quoting is needed for display name
            let needsQuoting = displayName.contains(where: {
                !$0.ascii.isLetter && !$0.ascii.isDigit && !$0.ascii.isWhitespace || $0.asciiValue == nil
            })

            if needsQuoting {
                result.append(.ascii.dquote)
                result.append(utf8: displayName)
                result.append(.ascii.dquote)
            } else {
                result.append(utf8: displayName)
            }

            result.append(.ascii.space)
            result.append(.ascii.lt)

            // Serialize local-part through bytes
            result.append(contentsOf: [UInt8](emailAddress.localPart))
            result.append(.ascii.at)

            // Serialize domain through bytes
            result.append(contentsOf: [UInt8](emailAddress.domain))

            result.append(.ascii.gt)
        } else {
            // Simple format without display name
            result.append(contentsOf: [UInt8](emailAddress.localPart))
            result.append(.ascii.at)
            result.append(contentsOf: [UInt8](emailAddress.domain))
        }

        self = result
    }
}

extension RFC_5322.EmailAddress {
    /// Just the email address part without display name
    public var address: String {
        "\(localPart)@\(domain.name)"
    }
}

extension RFC_5322.EmailAddress: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        try self.init(rawValue)
    }
}

extension RFC_5322.EmailAddress: RawRepresentable {
    public var rawValue: String { String(self) }
    public init?(rawValue: String) { try? self.init(rawValue) }
}
