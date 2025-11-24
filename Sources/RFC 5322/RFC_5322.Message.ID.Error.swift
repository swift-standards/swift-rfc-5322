//
//  RFC_5322.Message.ID.Error.swift
//  swift-rfc-5322
//
//  Error types for RFC 5322 Message-ID parsing
//

extension RFC_5322.Message.ID {
    /// Error type for RFC 5322 Message-ID parsing
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Missing @ separator in Message-ID
        case missingAtSign(String)

        /// Invalid character in Message-ID (must be printable ASCII, no spaces)
        case invalidCharacter(String, byte: UInt8, reason: String)
    }
}
