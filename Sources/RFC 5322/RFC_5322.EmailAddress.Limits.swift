//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 24/11/2025.
//

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
