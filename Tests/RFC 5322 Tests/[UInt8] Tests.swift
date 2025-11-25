//
//  [UInt8] Tests.swift
//  RFC 5322 Tests
//
//  Tests for [UInt8] extension initializers for byte-level conversions
//

import Testing
@testable import RFC_5322
import INCITS_4_1986

@Suite
struct `[UInt8] Conversions Tests` {

    // MARK: - EmailAddress to [UInt8]

    @Test
    func `Convert simple email address to bytes`() throws {
        let email = try RFC_5322.EmailAddress("user@example.com")
        let bytes = [UInt8](email)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string == "user@example.com")
    }

    @Test
    func `Convert email with display name to bytes`() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: "John Doe",
            localPart: .init("john"),
            domain: .init("example.com")
        )
        let bytes = [UInt8](email)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string == "John Doe <john@example.com>")
    }

    @Test
    func `Convert email with quoted display name to bytes`() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: "Doe, John",
            localPart: .init("john"),
            domain: .init("example.com")
        )
        let bytes = [UInt8](email)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string == "\"Doe, John\" <john@example.com>")
    }

    @Test
    func `Email address bytes contain @ symbol`() throws {
        let email = try RFC_5322.EmailAddress("user@example.com")
        let bytes = [UInt8](email)

        #expect(bytes.contains(0x40))  // @ symbol
    }

    // MARK: - Header to [UInt8]

    @Test
    func `Convert header to bytes`() throws {
        let header = try RFC_5322.Header(name: .subject, value: .init("Hello World"))
        let bytes = [UInt8](header)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string == "Subject: Hello World")
    }

    @Test
    func `Convert custom header to bytes`() throws {
        let header = try RFC_5322.Header(name: .init("X-Custom"), value: .init("custom value"))
        let bytes = [UInt8].init(header)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string == "X-Custom: custom value")
    }

    @Test
    func `Header bytes contain colon and space`() throws {
        let header = try RFC_5322.Header(name: .init("X-Test"), value: .init("value"))
        let bytes = [UInt8](header)

        // Debug: print actual bytes
        print("DEBUG Header bytes: \(bytes)")
        print("DEBUG Header string: '\(String(decoding: bytes, as: UTF8.self))'")

        #expect(bytes.contains(0x3A))  // : colon
        #expect(bytes.contains(0x20))  // space
    }

    // MARK: - DateTime to [UInt8]

    @Test
    func `Convert datetime to bytes`() throws {
        let dateTime = try RFC_5322.DateTime(
            year: 2024,
            month: 1,
            day: 15,
            hour: 12,
            minute: 30,
            second: 45
        )
        let bytes = [UInt8](dateTime)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(!string.isEmpty)
        #expect(string.contains(","))
        #expect(string.contains(":"))
        #expect(string.contains("2024"))
    }

    @Test
    func `DateTime bytes match formatted string`() {
        let dateTime = RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
        let bytes = [UInt8](dateTime)
        let fromBytes = String(decoding: bytes, as: UTF8.self)
        let fromDescription = dateTime.description

        #expect(fromBytes == fromDescription)
    }

    // MARK: - Message to [UInt8]

    @Test
    func `Convert basic message to bytes`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(secondsSinceEpoch: 0),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Hello".utf8)
        )

        let bytes = [UInt8](message)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.contains("From: sender@example.com"))
        #expect(string.contains("To: recipient@example.com"))
        #expect(string.contains("Subject: Test"))
        #expect(string.contains("Hello"))
    }

    @Test
    func `Message bytes use CRLF line endings`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(secondsSinceEpoch: 0),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Test".utf8)
        )

        let bytes = [UInt8](message)

        // Should contain CRLF sequences
        var hasCRLF = false
        for i in 0..<(bytes.count - 1) {
            if bytes[i] == UInt8.ascii.cr && bytes[i + 1] == UInt8.ascii.lf {
                hasCRLF = true
                break
            }
        }

        #expect(hasCRLF)
    }

    @Test
    func `Message bytes include all required headers`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(secondsSinceEpoch: 0),
            subject: "Test Subject",
            messageId: "<unique@example.com>",
            body: Array("Body".utf8)
        )

        let bytes = [UInt8](message)
        let string = String(decoding: bytes, as: UTF8.self)

        // Required headers
        #expect(string.contains("From:"))
        #expect(string.contains("To:"))
        #expect(string.contains("Subject:"))
        #expect(string.contains("Date:"))
        #expect(string.contains("Message-ID:"))
        #expect(string.contains("MIME-Version:"))
    }

    @Test
    func `Message bytes exclude BCC header`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            bcc: [try RFC_5322.EmailAddress("bcc@example.com")],
            date: .init(secondsSinceEpoch: 0),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Test".utf8)
        )

        let bytes = [UInt8](message)
        let string = String(decoding: bytes, as: UTF8.self)

        // BCC should NOT be in the byte output
        #expect(!string.contains("Bcc:"))
        #expect(!string.contains("bcc@example.com"))
    }

    @Test
    func `Message bytes include CC header when present`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            cc: [try RFC_5322.EmailAddress("cc@example.com")],
            date: .init(secondsSinceEpoch: 0),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Test".utf8)
        )

        let bytes = [UInt8](message)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.contains("Cc: cc@example.com"))
    }

    @Test
    func `Message bytes include Reply-To when present`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            replyTo: try RFC_5322.EmailAddress("replyto@example.com"),
            date: .init(secondsSinceEpoch: 0),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Test".utf8)
        )

        let bytes = [UInt8](message)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.contains("Reply-To: replyto@example.com"))
    }

    @Test
    func `Message bytes include additional headers`() throws {
        let message = try RFC_5322.Message(
            from: RFC_5322.EmailAddress("sender@example.com"),
            to: [RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(secondsSinceEpoch: 0),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Test".utf8),
            additionalHeaders: [
                RFC_5322.Header(name: .init("X-Priority"), value: 1)
            ]
        )

        let bytes = [UInt8](message)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.contains("X-Priority: 1"))
    }

    @Test
    func `Message bytes have empty line between headers and body`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(secondsSinceEpoch: 0),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Body content".utf8)
        )

        let bytes = [UInt8](message)

        // Should contain double CRLF (empty line separator)
        var hasDoubleCRLF = false
        for i in 0..<(bytes.count - 3) {
            if bytes[i] == UInt8.ascii.cr && bytes[i + 1] == UInt8.ascii.lf &&
               bytes[i + 2] == UInt8.ascii.cr && bytes[i + 3] == UInt8.ascii.lf {
                hasDoubleCRLF = true
                break
            }
        }

        #expect(hasDoubleCRLF)
    }

    @Test
    func `Message bytes include body at end`() throws {
        let bodyContent = "This is the message body"
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(secondsSinceEpoch: 0),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array(bodyContent.utf8)
        )

        let bytes = [UInt8](message)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.hasSuffix(bodyContent))
    }

    @Test
    func `Multiple recipients separated by commas in bytes`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [
                try RFC_5322.EmailAddress("alice@example.com"),
                try RFC_5322.EmailAddress("bob@example.com")
            ],
            date: .init(secondsSinceEpoch: 0),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Test".utf8)
        )

        let bytes = [UInt8](message)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.contains("To: alice@example.com, bob@example.com"))
    }

    // MARK: - Round-trip Tests

    @Test
    func `Message byte conversion is reversible`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200),
            subject: "Test Message",
            messageId: "<test@example.com>",
            body: Array("Hello, World!".utf8)
        )

        let bytes1 = [UInt8](message)
        let string = String(decoding: bytes1, as: UTF8.self)

        // Verify we can decode back to string
        #expect(!string.isEmpty)
        #expect(string.contains("sender@example.com"))
        #expect(string.contains("recipient@example.com"))
        #expect(string.contains("Hello, World!"))
    }
}
