//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 24/11/2025.
//

// MARK: - Header Error Type

extension RFC_5322.EmailAddress.LocalPart {
    /// Header-specific error type for typed throws
    public enum Error: Swift.Error, Sendable, Equatable {
        case nonASCIICharacters
        case tooLong(_ length: Int)
        case invalidQuotedString
        case invalidDotAtom
        case consecutiveDots
        case leadingOrTrailingDot
    }
}
