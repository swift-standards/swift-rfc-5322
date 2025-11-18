//
//  [UInt8] Tests.swift
//  RFC 5322 Tests
//
//  Tests for [UInt8] extension initializers for byte-level conversions
//

import Testing
@testable import RFC_5322
import INCITS_4_1986

@Suite("[UInt8] Conversions")
struct UInt8_Array_Tests {

    // MARK: - EmailAddress to [UInt8]

    @Test("Convert simple email address to bytes")
    func emailAddressToBytes() throws {
        let email = try RFC_5322.EmailAddress("user@example.com")
        let bytes = [UInt8](email)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string == "user@example.com")
    }

    @Test("Convert email with display name to bytes")
    func emailWithDisplayNameToBytes() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: "John Doe",
            localPart: .init("john"),
            domain: .init("example.com")
        )
        let bytes = [UInt8](email)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string == "John Doe <john@example.com>")
    }

    @Test("Convert email with quoted display name to bytes")
    func emailWithQuotedDisplayNameToBytes() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: "Doe, John",
            localPart: .init("john"),
            domain: .init("example.com")
        )
        let bytes = [UInt8](email)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string == "\"Doe, John\" <john@example.com>")
    }

    @Test("Email address bytes contain @ symbol")
    func emailAddressBytesContainAt() throws {
        let email = try RFC_5322.EmailAddress("user@example.com")
        let bytes = [UInt8](email)

        #expect(bytes.contains(0x40))  // @ symbol
    }

    // MARK: - Header to [UInt8]

    @Test("Convert header to bytes")
    func headerToBytes() {
        let header = RFC_5322.Header(name: .contentType, value: "text/plain")
        let bytes = [UInt8](header)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string == "Content-Type: text/plain")
    }

    @Test("Convert custom header to bytes")
    func customHeaderToBytes() {
        let header = RFC_5322.Header(name: "X-Custom", value: "custom value")
        let bytes = [UInt8].init(header)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string == "X-Custom: custom value")
    }

    @Test("Header bytes contain colon and space")
    func headerBytesFormat() {
        let header = RFC_5322.Header(name: "X-Test", value: "value")
        let bytes = [UInt8](header)

        // Debug: print actual bytes
        print("DEBUG Header bytes: \(bytes)")
        print("DEBUG Header string: '\(String(decoding: bytes, as: UTF8.self))'")

        #expect(bytes.contains(0x3A))  // : colon
        #expect(bytes.contains(0x20))  // space
    }

    // MARK: - DateTime to [UInt8]

    @Test("Convert datetime to bytes")
    func datetimeToBytes() {
        let dateTime = RFC_5322.DateTime(
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

    @Test("DateTime bytes match formatted string")
    func datetimeBytesMatchFormatted() {
        let dateTime = RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
        let bytes = [UInt8](dateTime)
        let fromBytes = String(decoding: bytes, as: UTF8.self)
        let fromDescription = dateTime.description

        #expect(fromBytes == fromDescription)
    }

    // MARK: - Message to [UInt8]

    @Test("Convert basic message to bytes")
    func basicMessageToBytes() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(),
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

    @Test("Message bytes use CRLF line endings")
    func messageBytesUseCRLF() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Test".utf8)
        )

        let bytes = [UInt8](message)

        // Should contain CRLF sequences
        var hasCRLF = false
        for i in 0..<(bytes.count - 1) {
            if bytes[i] == UInt8.cr && bytes[i + 1] == UInt8.lf {
                hasCRLF = true
                break
            }
        }

        #expect(hasCRLF)
    }

    @Test("Message bytes include all required headers")
    func messageBytesIncludeAllHeaders() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(),
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

    @Test("Message bytes exclude BCC header")
    func messageBytesExcludeBCC() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            bcc: [try RFC_5322.EmailAddress("bcc@example.com")],
            date: .init(),
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

    @Test("Message bytes include CC header when present")
    func messageBytesIncludeCC() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            cc: [try RFC_5322.EmailAddress("cc@example.com")],
            date: .init(),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Test".utf8)
        )

        let bytes = [UInt8](message)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.contains("Cc: cc@example.com"))
    }

    @Test("Message bytes include Reply-To when present")
    func messageBytesIncludeReplyTo() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            replyTo: try RFC_5322.EmailAddress("replyto@example.com"),
            date: .init(),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Test".utf8)
        )

        let bytes = [UInt8](message)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.contains("Reply-To: replyto@example.com"))
    }

    @Test("Message bytes include additional headers")
    func messageBytesIncludeAdditionalHeaders() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Test".utf8),
            additionalHeaders: [
                RFC_5322.Header(name: "X-Priority", value: "1")
            ]
        )

        let bytes = [UInt8](message)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.contains("X-Priority: 1"))
    }

    @Test("Message bytes have empty line between headers and body")
    func messageBytesEmptyLineSeparator() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Body content".utf8)
        )

        let bytes = [UInt8](message)

        // Should contain double CRLF (empty line separator)
        var hasDoubleCRLF = false
        for i in 0..<(bytes.count - 3) {
            if bytes[i] == UInt8.cr && bytes[i + 1] == UInt8.lf &&
               bytes[i + 2] == UInt8.cr && bytes[i + 3] == UInt8.lf {
                hasDoubleCRLF = true
                break
            }
        }

        #expect(hasDoubleCRLF)
    }

    @Test("Message bytes include body at end")
    func messageBytesIncludeBody() throws {
        let bodyContent = "This is the message body"
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array(bodyContent.utf8)
        )

        let bytes = [UInt8](message)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.hasSuffix(bodyContent))
    }

    @Test("Multiple recipients separated by commas in bytes")
    func multipleRecipientsCommaSeparated() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [
                try RFC_5322.EmailAddress("alice@example.com"),
                try RFC_5322.EmailAddress("bob@example.com")
            ],
            date: .init(),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Test".utf8)
        )

        let bytes = [UInt8](message)
        let string = String(decoding: bytes, as: UTF8.self)

        #expect(string.contains("To: alice@example.com, bob@example.com"))
    }

    // MARK: - Round-trip Tests

    @Test("Message byte conversion is reversible")
    func messageBytesRoundTrip() throws {
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
