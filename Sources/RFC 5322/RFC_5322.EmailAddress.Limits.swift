//
//  RFC_5322.EmailAddress.Limits.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 24/11/2025.
//

import INCITS_4_1986

// MARK: - Constants and Validation
extension RFC_5322.EmailAddress {
    package enum Limits {
        static let maxLength = 64  // Max length for local-part
    }

    // Address format regex with optional display name
    nonisolated(unsafe) package static let addressRegex = /(?:((?:\".*?\"|[^<]+)\s+))?<(.*?)@(.*?)>/

    // Dot-atom regex: series of atoms separated by dots
    // RFC 5322 Section 3.2.3 defines atext (RFC 5321 references this same definition)
    // atext = ALPHA / DIGIT / "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" / "`" / "{" / "|" / "}" / "~"
    nonisolated(unsafe) package static let dotAtomRegex =
        /[a-zA-Z0-9!#$%&'\*\+\-\/=\?\^_`\{\|}~]+(?:\.[a-zA-Z0-9!#$%&'\*\+\-\/=\?\^_`\{\|}~]+)*/

    // Quoted string regex: allows any printable character except unescaped quotes
    nonisolated(unsafe) package static let quotedRegex = /(?:[^"\\\r\n]|\\["\\])+/
}

// MARK: - atext Character Set

extension RFC_5322 {
    /// ASCII symbol bytes allowed in `atext` per RFC 5322 Section 3.2.3
    ///
    /// The `atext` rule defines printable US-ASCII characters that can appear in atoms:
    /// ```
    /// atext = ALPHA / DIGIT /    ; Printable US-ASCII
    ///         "!" / "#" /        ;  characters not including
    ///         "$" / "%" /        ;  specials. Used for atoms.
    ///         "&" / "'" /
    ///         "*" / "+" /
    ///         "-" / "/" /
    ///         "=" / "?" /
    ///         "^" / "_" /
    ///         "`" / "{" /
    ///         "|" / "}" /
    ///         "~"
    /// ```
    ///
    /// This set contains only the special symbols; ALPHA and DIGIT should be checked
    /// separately using `byte.ascii.isLetter` and `byte.ascii.isDigit`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// func isAtext(_ byte: UInt8) -> Bool {
    ///     byte.ascii.isLetter || byte.ascii.isDigit || RFC_5322.atextSymbols.contains(byte)
    /// }
    /// ```
    public static let atextSymbols: Set<UInt8> = [
        UInt8.ascii.exclamationPoint,        // ! (0x21)
        UInt8.ascii.numberSign,              // # (0x23)
        UInt8.ascii.dollarSign,              // $ (0x24)
        UInt8.ascii.percentSign,             // % (0x25)
        UInt8.ascii.ampersand,               // & (0x26)
        UInt8.ascii.apostrophe,              // ' (0x27)
        UInt8.ascii.asterisk,                // * (0x2A)
        UInt8.ascii.plusSign,                // + (0x2B)
        UInt8.ascii.hyphen,                  // - (0x2D)
        UInt8.ascii.solidus,                 // / (0x2F)
        UInt8.ascii.equalsSign,              // = (0x3D)
        UInt8.ascii.questionMark,            // ? (0x3F)
        UInt8.ascii.circumflexAccent,        // ^ (0x5E)
        UInt8.ascii.underline,               // _ (0x5F)
        UInt8.ascii.leftSingleQuotationMark, // ` (0x60)
        UInt8.ascii.leftBrace,               // { (0x7B)
        UInt8.ascii.verticalLine,            // | (0x7C)
        UInt8.ascii.rightBrace,              // } (0x7D)
        UInt8.ascii.tilde,                   // ~ (0x7E)
    ]

    /// Tests if an ASCII byte is a valid `atext` character per RFC 5322 Section 3.2.3
    ///
    /// Returns `true` if the byte is ALPHA, DIGIT, or one of the allowed symbols.
    ///
    /// - Parameter byte: The ASCII byte to test
    /// - Returns: `true` if the byte is valid in an atom
    @inlinable
    public static func isAtext(_ byte: UInt8) -> Bool {
        byte.ascii.isLetter || byte.ascii.isDigit || atextSymbols.contains(byte)
    }
}
