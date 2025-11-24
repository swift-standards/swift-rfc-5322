//
//  RFC_5322.Message.Error.swift
//  swift-rfc-5322
//
//  Error types for RFC 5322 Message parsing
//

extension RFC_5322.Message {
    /// Error type for RFC 5322 message parsing
    ///
    /// **FUTURE TASK**: These error cases will be used when message parsing is implemented.
    ///
    /// Message parsing is complex and can fail in many ways:
    /// - Malformed headers
    /// - Missing required headers
    /// - Invalid header folding
    /// - MIME structure errors
    /// - Encoding errors
    public enum Error: Swift.Error, Sendable, Equatable {
        // FUTURE: Header parsing errors
        case missingRequiredHeader(String)  // e.g., "From", "Date"
        case invalidHeaderFormat(String)
        case headerFoldingError(String)

        // FUTURE: Structure errors
        case invalidMessageStructure(String)
        case missingHeaderBodySeparator

        // FUTURE: MIME errors
        case invalidMimeStructure(String)
        case unsupportedEncoding(String)

        // FUTURE: Component errors (wrapping sub-parsers)
        case emailAddress(RFC_5322.EmailAddress.Error)
        case dateTime(RFC_5322.DateTime.Error)
        case header(RFC_5322.Header.Error)

        // FUTURE: Generic error
        case parsingFailed(String)
    }
}
