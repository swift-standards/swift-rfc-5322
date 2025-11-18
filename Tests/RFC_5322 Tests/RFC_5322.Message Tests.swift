//
//  RFC_5322.Message Tests.swift
//  RFC 5322 Tests
//
//  Tests for RFC_5322.Message including creation, rendering, and validation
//

import Testing
@testable import RFC_5322

@Suite("RFC_5322.Message")
struct RFC_5322_Message_Tests {

    // MARK: - Basic Message Creation

    @Test("Create basic message with required fields")
    func createBasicMessage() throws {
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

        #expect(message.from.addressValue == "sender@example.com")
        #expect(message.to.count == 1)
        #expect(message.to[0].addressValue == "recipient@example.com")
        #expect(message.subject == "Test Message")
        #expect(message.messageId == "<test@example.com>")
        #expect(String(decoding: message.body, as: UTF8.self) == "Hello, World!")
    }

    @Test("Create message with multiple recipients")
    func createMessageWithMultipleRecipients() throws {
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
        #expect(message.to[0].addressValue == "alice@example.com")
        #expect(message.to[1].addressValue == "bob@example.com")
        #expect(message.to[2].addressValue == "charlie@example.com")
    }

    @Test("Create message with CC recipients")
    func createMessageWithCC() throws {
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
        #expect(message.cc?[0].addressValue == "cc@example.com")
    }

    @Test("Create message with BCC recipients")
    func createMessageWithBCC() throws {
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
        #expect(message.bcc?[0].addressValue == "bcc@example.com")
    }

    @Test("Create message with Reply-To")
    func createMessageWithReplyTo() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            replyTo: try RFC_5322.EmailAddress("replyto@example.com"),
            date: .init(),
            subject: "Test Reply-To",
            messageId: "<reply-test@example.com>",
            body: .init(utf8: "Test")
        )

        #expect(message.replyTo?.addressValue == "replyto@example.com")
    }

    // MARK: - Additional Headers

    @Test("Create message with additional headers")
    func createMessageWithAdditionalHeaders() throws {
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

    @Test("Create message with custom MIME version")
    func createMessageWithCustomMimeVersion() throws {
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

    @Test("Default MIME version is 1.0")
    func defaultMimeVersion() throws {
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

    @Test("Render message to string contains all required headers")
    func renderMessageContainsHeaders() throws {
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

    @Test("Render message with display names")
    func renderMessageWithDisplayNames() throws {
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

    @Test("Render message does not include BCC header")
    func renderMessageExcludesBCC() throws {
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

    @Test("Render message includes CC header")
    func renderMessageIncludesCC() throws {
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

    @Test("Render message includes Reply-To header")
    func renderMessageIncludesReplyTo() throws {
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

    @Test("Render message includes additional headers")
    func renderMessageIncludesAdditionalHeaders() throws {
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

    @Test("Generate message ID format")
    func generateMessageIdFormat() throws {
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
