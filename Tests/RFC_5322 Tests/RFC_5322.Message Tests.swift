//
//  RFC_5322.Message Tests.swift
//  RFC 5322 Tests
//
//  Tests for RFC_5322.Message including creation, rendering, and validation
//

import Testing
@testable import RFC_5322

@Suite
struct `RFC_5322.Message Tests` {

    // MARK: - Basic Message Creation

    @Test
    func `Create basic message with required fields`() throws {
        let from = try RFC_5322.EmailAddress("sender@example.com")
        let to = [try RFC_5322.EmailAddress("recipient@example.com")]

        let message = RFC_5322.Message(
            from: from,
            to: to,
            date: .init(),
            subject: "Test Message",
            messageId: "<test@example.com>",
            body: .init("Hello, World!".utf8)
        )

        #expect(message.from.address == "sender@example.com")
        #expect(message.to.count == 1)
        #expect(message.to[0].address == "recipient@example.com")
        #expect(message.subject == "Test Message")
        #expect(message.messageId == "<test@example.com>")
        #expect(String(decoding: message.body, as: UTF8.self) == "Hello, World!")
    }

    @Test
    func `Create message with multiple recipients`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [
                try RFC_5322.EmailAddress("alice@example.com"),
                try RFC_5322.EmailAddress("bob@example.com"),
                try RFC_5322.EmailAddress("charlie@example.com")
            ],
            date: .init(),
            subject: "Group Message",
            messageId: "<group@example.com>",
            body: .init(utf8: "Hello")
        )

        #expect(message.to.count == 3)
        #expect(message.to[0].address == "alice@example.com")
        #expect(message.to[1].address == "bob@example.com")
        #expect(message.to[2].address == "charlie@example.com")
    }

    @Test
    func `Create message with CC recipients`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("primary@example.com")],
            cc: [try RFC_5322.EmailAddress("cc@example.com")],
            date: .init(),
            subject: "Test CC",
            messageId: "<cc-test@example.com>",
            body: .init(utf8: "Test")
        )

        #expect(message.cc?.count == 1)
        #expect(message.cc?[0].address == "cc@example.com")
    }

    @Test
    func `Create message with BCC recipients`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("primary@example.com")],
            bcc: [try RFC_5322.EmailAddress("bcc@example.com")],
            date: .init(),
            subject: "Test BCC",
            messageId: "<bcc-test@example.com>",
            body: .init(utf8: "Test")
        )

        #expect(message.bcc?.count == 1)
        #expect(message.bcc?[0].address == "bcc@example.com")
    }

    @Test
    func `Create message with Reply-To`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            replyTo: try RFC_5322.EmailAddress("replyto@example.com"),
            date: .init(),
            subject: "Test Reply-To",
            messageId: "<reply-test@example.com>",
            body: .init(utf8: "Test")
        )

        #expect(message.replyTo?.address == "replyto@example.com")
    }

    // MARK: - Additional Headers

    @Test
    func `Create message with additional headers`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(),
            subject: "Test Headers",
            messageId: "<headers-test@example.com>",
            body: .init(utf8: "Test"),
            additionalHeaders: [
                RFC_5322.Header(name: "X-Priority", value: "1"),
                RFC_5322.Header(name: .contentType, value: "text/plain; charset=utf-8")
            ]
        )

        #expect(message.additionalHeaders.count == 2)
        #expect(message.additionalHeaders[0].name.rawValue == "X-Priority")
        #expect(message.additionalHeaders[0].value == "1")
        #expect(message.additionalHeaders[1].name == .contentType)
    }

    // MARK: - MIME Version

    @Test
    func `Create message with custom MIME version`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(),
            subject: "Test MIME",
            messageId: "<mime-test@example.com>",
            body: .init(utf8: "Test"),
            mimeVersion: "2.0"
        )

        #expect(message.mimeVersion == "2.0")
    }

    @Test
    func `Default MIME version is 1.0`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(),
            subject: "Test",
            messageId: "<test@example.com>",
            body: .init(utf8: "Test")
        )

        #expect(message.mimeVersion == "1.0")
    }

    // MARK: - Message Rendering

    @Test
    func `Render message to string contains all required headers`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200),
            subject: "Test Message",
            messageId: "<test@example.com>",
            body: .init("Hello, World!".utf8)
        )

        let rendered = String(message)

        #expect(rendered.contains("From: sender@example.com"))
        #expect(rendered.contains("To: recipient@example.com"))
        #expect(rendered.contains("Subject: Test Message"))
        #expect(rendered.contains("Message-ID: <test@example.com>"))
        #expect(rendered.contains("MIME-Version: 1.0"))
        #expect(rendered.contains("Hello, World!"))
    }

    @Test
    func `Render message with display names`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress(
                displayName: "John Doe",
                localPart: .init("john"),
                domain: .init("example.com")
            ),
            to: [try RFC_5322.EmailAddress("Jane Smith <jane@example.com>")],
            date: .init(),
            subject: "Test",
            messageId: "<test@example.com>",
            body: .init(utf8: "Test")
        )

        let rendered = String(message)

        #expect(rendered.contains("From: John Doe <john@example.com>"))
        #expect(rendered.contains("To: Jane Smith <jane@example.com>"))
    }

    @Test
    func `Render message does not include BCC header`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            bcc: [try RFC_5322.EmailAddress("bcc@example.com")],
            date: .init(),
            subject: "Test BCC",
            messageId: "<bcc-test@example.com>",
            body: .init(utf8: "Test")
        )

        let rendered = String(message)

        // BCC should NOT appear in rendered message per RFC 5322
        #expect(!rendered.contains("Bcc:"))
        #expect(!rendered.contains("bcc@example.com"))
    }

    @Test
    func `Render message includes CC header`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            cc: [try RFC_5322.EmailAddress("cc@example.com")],
            date: .init(),
            subject: "Test CC",
            messageId: "<cc-test@example.com>",
            body: .init(utf8: "Test")
        )

        let rendered = String(message)

        #expect(rendered.contains("Cc: cc@example.com"))
    }

    @Test
    func `Render message includes Reply-To header`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            replyTo: try RFC_5322.EmailAddress("replyto@example.com"),
            date: .init(),
            subject: "Test",
            messageId: "<test@example.com>",
            body: .init(utf8: "Test")
        )

        let rendered = String(message)

        #expect(rendered.contains("Reply-To: replyto@example.com"))
    }

    @Test
    func `Render message includes additional headers`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(),
            subject: "Test",
            messageId: "<test@example.com>",
            body: .init(utf8: "Test"),
            additionalHeaders: [
                RFC_5322.Header(name: "X-Priority", value: "1")
            ]
        )

        let rendered = String(message)

        #expect(rendered.contains("X-Priority: 1"))
    }

    // MARK: - Generate Message ID

    @Test
    func `Generate message ID format`() throws {
        let from = try RFC_5322.EmailAddress("sender@example.com")
        let messageId = RFC_5322.Message.generateMessageId(
            from: from,
            uniqueId: "test-123"
        )

        #expect(messageId == "<test-123@example.com>")
        #expect(messageId.hasPrefix("<"))
        #expect(messageId.hasSuffix(">"))
        #expect(messageId.contains("@"))
    }
}
