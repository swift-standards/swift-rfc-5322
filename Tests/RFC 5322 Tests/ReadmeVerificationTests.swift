//
//  ReadmeVerificationTests.swift
//  swift-rfc-5322
//
//  Verifies that README code examples actually work
//

import RFC_5322
import Testing

@Suite
struct `README Verification Tests` {

    @Test
    func `README Line 54-57: Parse email address`() throws {
        let email = try RFC_5322.EmailAddress("user@example.com")
        #expect(email.localPart.description == "user")
        #expect(email.domain.name == "example.com")
    }

    @Test
    func `README Line 59-62: Parse with display name`() throws {
        let named = try RFC_5322.EmailAddress("John Doe <john@example.com>")
        #expect(named.displayName == "John Doe")
        #expect(named.address == "john@example.com")
    }

    @Test
    func `README Line 64-69: Create from components`() throws {
        let addr = try RFC_5322.EmailAddress(
            displayName: "Jane Smith",
            localPart: .init("jane"),
            domain: .init("example.com")
        )
        #expect(addr.displayName == "Jane Smith")
        #expect(addr.localPart.description == "jane")
        #expect(addr.domain.name == "example.com")
    }

    @Test
    func `README Line 75-89: Create a message`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress(
                displayName: "John Doe",
                localPart: .init("john"),
                domain: .init("example.com")
            ),
            to: [try RFC_5322.EmailAddress("jane@example.com")],
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200),
            subject: "Hello from Swift!",
            messageId: RFC_5322.Message.generateMessageId(
                from: try RFC_5322.EmailAddress("john@example.com"),
                uniqueId: "test-unique-id"
            ),
            body: Array("Hello, World!".utf8)
        )

        #expect(message.from.displayName == "John Doe")
        #expect(message.to.count == 1)
        #expect(message.subject == "Hello from Swift!")
        #expect(String(message.body) == "Hello, World!")
    }

    @Test
    func `README Line 91-92: Render message`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress(
                displayName: "John Doe",
                localPart: .init("john"),
                domain: .init("example.com")
            ),
            to: [try RFC_5322.EmailAddress("jane@example.com")],
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200),
            subject: "Hello from Swift!",
            messageId: "<test@example.com>",
            body: Array("Hello, World!".utf8)
        )

        let emlContent = String(message)
        #expect(emlContent.contains("From: John Doe <john@example.com>"))
        #expect(emlContent.contains("To: jane@example.com"))
        #expect(emlContent.contains("Subject: Hello from Swift!"))
        #expect(emlContent.contains("Message-ID: <test@example.com>"))
        #expect(emlContent.contains("Hello, World!"))
    }

    @Test
    func `README Line 107-122: Advanced message features`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            cc: [try RFC_5322.EmailAddress("cc@example.com")],
            bcc: [try RFC_5322.EmailAddress("bcc@example.com")],
            replyTo: try RFC_5322.EmailAddress("replyto@example.com"),
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200),
            subject: "Meeting Notes",
            messageId: "<unique-id@example.com>",
            body: Array("Meeting summary...".utf8),
            additionalHeaders: [
                RFC_5322.Header(name: RFC_5322.Header.Name("X-Priority"), value: "1"),
                RFC_5322.Header(name: RFC_5322.Header.Name("X-Mailer"), value: "Custom Mailer"),
            ]
        )

        #expect(message.cc?.count == 1)
        #expect(message.bcc?.count == 1)
        #expect(message.replyTo?.address == "replyto@example.com")
        #expect(message.additionalHeaders.count == 2)
    }

    @Test
    func `README Line 128-129: Format date`() throws {
        let dateTime = RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
        let dateString = dateTime.format(dateTime)
        #expect(!dateString.isEmpty)
        // Should contain day, month, year, time
        #expect(dateString.contains(","))
    }
}
