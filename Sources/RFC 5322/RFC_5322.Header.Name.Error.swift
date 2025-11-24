//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 24/11/2025.
//

public import RFC_5322

extension RFC_5322.Header.Name {
    /// Header name-specific error type for typed throws
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Field name is empty
        case empty

        /// Field name contains invalid character
        case invalidCharacter(String, byte: UInt8, reason: String)
    }
}
