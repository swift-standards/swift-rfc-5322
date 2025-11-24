//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 24/11/2025.
//

public import RFC_5322

// MARK: - Header.Value Error Type

extension RFC_5322.Header.Value {
    /// Header value-specific error type for typed throws
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Invalid folding whitespace (future validation)
        case invalidFolding(String, reason: String)

        /// Invalid character in value (future validation)
        case invalidCharacter(String, reason: String)
    }
}
