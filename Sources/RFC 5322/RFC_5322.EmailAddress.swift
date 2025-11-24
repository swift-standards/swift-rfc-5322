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


extension RFC_5322.EmailAddress {
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
    public init(ascii bytes: [UInt8]) throws(Error) {
        // Look for angle brackets to determine format
        if let ltIndex = bytes.firstIndex(of: .ascii.lt),
           let gtIndex = bytes.lastIndex(of: .ascii.gt),
           ltIndex < gtIndex {
            
            // Format: "Display Name <local@domain>" or "Display Name" <local@domain>
            let displayNameBytes = bytes[..<ltIndex]
            let emailBytes = bytes[(ltIndex + 1)..<gtIndex]
            
            // Parse display name (trim whitespace)
            let displayName: String?
            if !displayNameBytes.isEmpty {
                let trimmedDisplayName = displayNameBytes.trimming(.ascii.whitespaces)
                
                if !trimmedDisplayName.isEmpty {
                    var nameString = String(decoding: trimmedDisplayName, as: UTF8.self)
                    
                    // Handle quoted display names: "Name" -> Name, with escape handling
                    if nameString.hasPrefix("\"") && nameString.hasSuffix("\"") {
                        nameString = String(nameString.dropFirst().dropLast())
                        // Handle escape sequences: \" -> ", \\ -> \
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
            guard let atIndex = emailBytes.firstIndex(of: .ascii.at) else {
                throw Error.missingAtSign
            }
            
            let localBytes = emailBytes[..<atIndex]
            let domainBytes = emailBytes[(atIndex + 1)...]
            
            // Parse local-part at byte level
            let localPartValue: LocalPart
            do {
                localPartValue = try LocalPart(ascii: Array(localBytes))
            } catch {
                throw Error.localPart(error)
            }
            
            // Parse domain at byte level
            let domainValue: RFC_1123.Domain
            do {
                domainValue = try RFC_1123.Domain(ascii: Array(domainBytes))
            } catch {
                throw Error.domain(error)
            }
            
            self.init(
                displayName: displayName,
                localPart: localPartValue,
                domain: domainValue
            )
        } else {
            // Simple format: local@domain
            guard let atIndex = bytes.firstIndex(of: .ascii.at) else {
                throw Error.missingAtSign
            }
            
            let localBytes = bytes[..<atIndex]
            let domainBytes = bytes[(atIndex + 1)...]
            
            // Parse local-part at byte level
            let localPartValue: LocalPart
            do {
                localPartValue = try LocalPart(ascii: Array(localBytes))
            } catch {
                throw Error.localPart(error)
            }
            
            // Parse domain at byte level
            let domainValue: RFC_1123.Domain
            do {
                domainValue = try RFC_1123.Domain(ascii: Array(domainBytes))
            } catch {
                throw Error.domain(error)
            }
            
            self.init(
                displayName: nil,
                localPart: localPartValue,
                domain: domainValue
            )
        }
    }
}

extension RFC_5322.EmailAddress {
    /// Initialize from string representation ("Name <local@domain>" or "local@domain")
    ///
    /// Composes through canonical byte representation for academic correctness.
    ///
    /// ## Category Theory
    ///
    /// Parsing composes as:
    /// ```
    /// String → [UInt8] (UTF-8) → EmailAddress
    /// ```
    ///
    /// Uses typed throws for proper error composition:
    /// - EmailAddress.Error for missing @ sign
    /// - LocalPart.Error wrapped in EmailAddress.Error.localPart
    /// - Domain errors wrapped in EmailAddress.Error.domain
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: Array(string.utf8))
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

// MARK: - Protocol Conformances
extension RFC_5322.EmailAddress: CustomStringConvertible {
    /// String representation of the email address
    ///
    /// Composes through canonical byte representation for academic correctness.
    ///
    /// ## Category Theory
    ///
    /// String display composes as:
    /// ```
    /// EmailAddress → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    public var description: String {
        String(decoding: [UInt8](self), as: UTF8.self)
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

extension StringProtocol {
    /// String representation of an RFC 5322 email address
    ///
    /// Composes through canonical byte representation for academic correctness.
    ///
    /// ## Category Theory
    ///
    /// String display composes as:
    /// ```
    /// EmailAddress → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    public init(_ emailAddress: RFC_5322.EmailAddress) {
        self = Self(decoding: [UInt8](emailAddress), as: UTF8.self)
    }
}
