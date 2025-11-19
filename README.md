# Swift RFC 5322

[![CI](https://github.com/swift-standards/swift-rfc-5322/workflows/CI/badge.svg)](https://github.com/swift-standards/swift-rfc-5322/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Swift implementation of RFC 5322: Internet Message Format - email message structure and formatting standard.

## Overview

RFC 5322 defines the Internet Message Format used for email messages. This package provides a pure Swift implementation of RFC 5322-compliant email address validation with extended features beyond RFC 5321, plus message composition with headers and body formatting suitable for generating .eml files.

The package handles email addresses with more permissive rules than SMTP (RFC 5321), supports message structure with proper header ordering, and provides utilities for date formatting and message rendering.

## Features

- **RFC 5322 Email Addresses**: Extended validation beyond SMTP with additional dot-atom rules
- **Internet Message Format**: Complete message structure with headers and body
- **Display Name Support**: Parse and format addresses with display names
- **Message Composition**: Create RFC 5322-compliant messages for .eml files
- **Date Formatting**: RFC 5322-compliant date/time formatting
- **Header Management**: Structured header handling with proper ordering
- **RFC 5321 Compatibility**: Convert between RFC 5322 and RFC 5321 formats
- **Type-Safe API**: Structured components with compile-time safety
- **Codable Support**: Seamless JSON encoding/decoding

## Installation

Add swift-rfc-5322 to your package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/swift-standards/swift-rfc-5322.git", from: "0.1.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RFC_5322", package: "swift-rfc-5322")
    ]
)
```

## Quick Start

### Email Addresses

```swift
import RFC_5322

// Parse email address
let email = try RFC_5322.EmailAddress("user@example.com")
print(email.localPart.stringValue) // "user"
print(email.domain.name) // "example.com"

// Parse with display name
let named = try RFC_5322.EmailAddress("John Doe <john@example.com>")
print(named.displayName) // "John Doe"
print(named.address) // "john@example.com"

// Create from components
let addr = try RFC_5322.EmailAddress(
    displayName: "Jane Smith",
    localPart: .init("jane"),
    domain: .init("example.com")
)
```

### Creating Messages

```swift
// Create a message
let message = RFC_5322.Message(
    from: try RFC_5322.EmailAddress(
        displayName: "John Doe",
        localPart: .init("john"),
        domain: .init("example.com")
    ),
    to: [try RFC_5322.EmailAddress("jane@example.com")],
    subject: "Hello from Swift!",
    date: Date(),
    messageId: RFC_5322.Message.generateMessageId(
        from: try RFC_5322.EmailAddress("john@example.com")
    ),
    body: "Hello, World!".data(using: .utf8)!
)

// Convert to RFC 5322 format
let emlContent = String(message)
print(emlContent)
// From: John Doe <john@example.com>
// To: jane@example.com
// Subject: Hello from Swift!
// Date: Tue, 12 Nov 2025 20:00:00 +0000
// Message-ID: <UUID@example.com>
// MIME-Version: 1.0
//
// Hello, World!
```

### Advanced Message Features

```swift
// Message with CC, BCC, and custom headers
let message = RFC_5322.Message(
    from: try RFC_5322.EmailAddress("sender@example.com"),
    to: [try RFC_5322.EmailAddress("recipient@example.com")],
    cc: [try RFC_5322.EmailAddress("cc@example.com")],
    bcc: [try RFC_5322.EmailAddress("bcc@example.com")],
    replyTo: try RFC_5322.EmailAddress("replyto@example.com"),
    subject: "Meeting Notes",
    date: Date(),
    messageId: "<unique-id@example.com>",
    body: "Meeting summary...".data(using: .utf8)!,
    additionalHeaders: [
        RFC_5322.Header(name: "X-Priority", value: "1"),
        RFC_5322.Header(name: .contentType, value: "text/plain; charset=utf-8")
    ]
)
```

### Date Formatting

```swift
// Format date in RFC 5322 format
let dateString = RFC_5322.Date.string(from: Date())
// "Tue, 12 Nov 2025 20:00:00 +0000"

// Parse RFC 5322 date
let date = try RFC_5322.Date.date(from: "Tue, 12 Nov 2025 20:00:00 +0000")
```

## Usage

### EmailAddress Type

Extended email address validation per RFC 5322:

```swift
public struct EmailAddress: Hashable, Sendable {
    public let displayName: String?
    public let localPart: LocalPart
    public let domain: Domain

    public init(displayName: String?, localPart: LocalPart, domain: Domain)
    public init(_ string: String) throws

    public var stringValue: String      // Full format with display name
    public var address: String     // Just the email address part
    public func toRFC5321() throws -> RFC_5321.EmailAddress
}
```

Key differences from RFC 5321:
- Stricter dot-atom rules (no `!` or `|` in local-part)
- Validates against consecutive dots
- Checks for leading/trailing dots in local-part

### Message Type

Complete Internet Message Format:

```swift
public struct Message: Hashable, Sendable {
    public let from: EmailAddress
    public let to: [EmailAddress]
    public let cc: [EmailAddress]?
    public let bcc: [EmailAddress]?
    public let replyTo: EmailAddress?
    public let subject: String
    public let date: Date
    public let messageId: String
    public let body: Data
    public let additionalHeaders: [Header]
    public let mimeVersion: String

    public var bodyString: String?
    public static func generateMessageId(from: EmailAddress, uniqueId: String) -> String
}

extension [UInt8] {
    public init(_ message: RFC_5322.Message)
}

extension String {
    public init(_ message: RFC_5322.Message)
}
```

### Header Type

Structured header management:

```swift
public struct Header: Hashable, Sendable {
    public let name: HeaderName
    public let value: String
}

public enum HeaderName {
    case from
    case to
    case cc
    case subject
    case date
    case messageId
    case contentType
    case custom(String)
}
```

## Related Packages

### Dependencies
- [swift-rfc-1123](https://github.com/swift-standards/swift-rfc-1123) - Domain name validation
- [swift-rfc-5321](https://github.com/swift-standards/swift-rfc-5321) - SMTP email address format

### Used By
- Email clients and server implementations
- Message composition tools
- .eml file generators

## Requirements

- Swift 6.0+
- macOS 13.0+ / iOS 16.0+

## License

This library is released under the Apache License 2.0. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
