//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 18/11/2025.
//

import INCITS_4_1986
import RFC_1123
import RegexBuilder

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
        public init(displayName: String? = nil, localPart: LocalPart, domain: RFC_1123.Domain) {
            self.displayName = displayName?.trimming(.whitespaces)
            self.localPart = localPart
            self.domain = domain
        }

        /// Initialize from string representation ("Name <local@domain>" or "local@domain")
        public init(_ string: String) throws {
            // Define regex components using Regex builder for more robust parsing
            let displayNameCapture = /((?:\"(?:(?:\\[\"\\])|[^\"\\])+\"|[^<]+?))\s*/

            let emailCapture = Regex {
                "<"
                Capture {
                    // Local part
                    OneOrMore(.reluctant) {
                        NegativeLookahead { "@" }
                        CharacterClass.any
                    }
                }
                "@"
                Capture {
                    // Domain
                    OneOrMore(.reluctant) {
                        NegativeLookahead { ">" }
                        CharacterClass.any
                    }
                }
                ">"
            }

            let fullRegex = Regex {
                Optionally {
                    displayNameCapture
                }
                emailCapture
            }

            // Try matching the full address format first (with angle brackets)
            if let match = try? fullRegex.wholeMatch(in: string) {
                let displayName = match.output.1.map { name in
                    let trimmedName = name.trimming(.whitespaces)
                    if trimmedName.hasPrefix("\"") && trimmedName.hasSuffix("\"") {
                        // For quoted strings, we need to:
                        // 1. Remove the outer quotes
                        // 2. Handle escaped characters
                        let withoutQuotes = String(trimmedName.dropFirst().dropLast())
                        return withoutQuotes.replacing( #"\""#, with: "\"")
                            .replacing( #"\\"#, with: "\\")
                    }
                    return trimmedName
                }

                let localPart = String(match.output.2)
                let domain = String(match.output.3)

                try self.init(
                    displayName: displayName,
                    localPart: LocalPart(localPart),
                    domain: RFC_1123.Domain(domain)
                )
            } else {
                // Try parsing as bare email address
                guard let atIndex = string.firstIndex(of: "@") else {
                    throw ValidationError.missingAtSign
                }

                let localString = String(string[..<atIndex])
                let domainString = String(string[string.index(after: atIndex)...])

                try self.init(
                    displayName: nil,
                    localPart: LocalPart(localString),
                    domain: RFC_1123.Domain(domainString)
                )
            }
        }
    }
}

// MARK: - Local Part
extension RFC_5322.EmailAddress {
    /// RFC 5322 compliant local-part
    public struct LocalPart: Hashable, Sendable, CustomStringConvertible {
        private let storage: Storage

        /// Initialize with a string
        public init(_ string: String) throws {
            // RFC 5322 is ASCII-only - validate before processing
            guard string.asciiBytes != nil else {
                throw ValidationError.nonASCIICharacters
            }

            // Check overall length first
            guard string.count <= Limits.maxLength else {
                throw ValidationError.localPartTooLong(string.count)
            }

            // Handle quoted string format
            if string.hasPrefix("\"") && string.hasSuffix("\"") {
                let quoted = String(string.dropFirst().dropLast())
                guard (try? RFC_5322.EmailAddress.quotedRegex.wholeMatch(in: quoted)) != nil else {
                    throw ValidationError.invalidQuotedString
                }
                self.storage = .quoted(string)
            }
            // Handle dot-atom format
            else {
                guard (try? RFC_5322.EmailAddress.dotAtomRegex.wholeMatch(in: string)) != nil else {
                    throw ValidationError.invalidDotAtom
                }
                // Check for consecutive dots
                guard !string.contains("..") else {
                    throw ValidationError.consecutiveDots
                }
                // Check for leading/trailing dots
                guard !string.hasPrefix(".") && !string.hasSuffix(".") else {
                    throw ValidationError.leadingOrTrailingDot
                }
                self.storage = .dotAtom(string)
            }
        }

        /// The string representation
        public var description: String {
            switch storage {
            case .dotAtom(let string), .quoted(let string):
                return string
            }
        }

        // swiftlint:disable:next nesting
        private enum Storage: Hashable {
            case dotAtom(String)  // Regular unquoted format
            case quoted(String)  // Quoted string format
        }
    }
}

// MARK: - Constants and Validation
extension RFC_5322.EmailAddress {
    private enum Limits {
        static let maxLength = 64  // Max length for local-part
    }

    // Address format regex with optional display name
    nonisolated(unsafe) private static let addressRegex = /(?:((?:\".*?\"|[^<]+)\s+))?<(.*?)@(.*?)>/

    // Dot-atom regex: series of atoms separated by dots
    // RFC 5322 Section 3.2.3 defines atext (RFC 5321 references this same definition)
    // atext = ALPHA / DIGIT / "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" / "`" / "{" / "|" / "}" / "~"
    nonisolated(unsafe) private static let dotAtomRegex =
        /[a-zA-Z0-9!#$%&'\*\+\-\/=\?\^_`\{\|}~]+(?:\.[a-zA-Z0-9!#$%&'\*\+\-\/=\?\^_`\{\|}~]+)*/

    // Quoted string regex: allows any printable character except unescaped quotes
    nonisolated(unsafe) private static let quotedRegex = /(?:[^"\\\r\n]|\\["\\])+/
}

extension RFC_5322.EmailAddress {
    /// Just the email address part without display name
    public var address: String {
        "\(localPart)@\(domain.name)"
    }
}

// MARK: - Errors
extension RFC_5322.EmailAddress {
    public enum ValidationError: Error, Equatable {
        case missingAtSign
        case invalidDotAtom
        case invalidQuotedString
        case localPartTooLong(_ length: Int)
        case consecutiveDots
        case leadingOrTrailingDot
        case nonASCIICharacters

        public var errorDescription: String? {
            switch self {
            case .missingAtSign:
                return "Email address must contain @"
            case .invalidDotAtom:
                return "Invalid local-part format (before @)"
            case .invalidQuotedString:
                return "Invalid quoted string format in local-part"
            case .localPartTooLong(let length):
                return "Local-part length \(length) exceeds maximum of \(Limits.maxLength)"
            case .consecutiveDots:
                return "Local-part cannot contain consecutive dots"
            case .leadingOrTrailingDot:
                return "Local-part cannot start or end with a dot"
            case .nonASCIICharacters:
                return "RFC 5322 email addresses must contain only ASCII characters"
            }
        }
    }
}

// MARK: - Protocol Conformances
extension RFC_5322.EmailAddress: CustomStringConvertible {
    public var description: String { String(self) }
}

extension RFC_5322.EmailAddress: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        try self.init(rawValue)
    }
}

extension RFC_5322.EmailAddress: RawRepresentable {
    public var rawValue: String { String(self) }
    public init?(rawValue: String) { try? self.init(rawValue) }
}
