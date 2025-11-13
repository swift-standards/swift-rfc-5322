//
//  ReadmeVerificationTests.swift
//  swift-rfc-5322
//
//  Verifies that README code examples actually work
//

import Foundation
import RFC_5322
import Testing

@Suite("README Verification")
struct ReadmeVerificationTests {

    @Test("README Line 54-57: Parse email address")
    func parseEmailAddress() throws {
        let email = try RFC_5322.EmailAddress("user@example.com")
        #expect(email.localPart.description == "user")
        #expect(email.domain.name == "example.com")
    }

    @Test("README Line 59-62: Parse with display name")
    func parseWithDisplayName() throws {
        let named = try RFC_5322.EmailAddress("John Doe <john@example.com>")
        #expect(named.displayName == "John Doe")
        #expect(named.addressValue == "john@example.com")
    }

    @Test("README Line 64-69: Create from components")
    func createFromComponents() throws {
        let addr = try RFC_5322.EmailAddress(
            displayName: "Jane Smith",
            localPart: .init("jane"),
            domain: .init("example.com")
        )
        #expect(addr.displayName == "Jane Smith")
        #expect(addr.localPart.description == "jane")
        #expect(addr.domain.name == "example.com")
    }

    @Test("README Line 75-89: Create a message")
    func createMessage() throws {
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
            body: Data("Hello, World!".utf8)
        )

        #expect(message.from.displayName == "John Doe")
        #expect(message.to.count == 1)
        #expect(message.subject == "Hello from Swift!")
        #expect(message.bodyString == "Hello, World!")
    }

    @Test("README Line 91-92: Render message")
    func renderMessage() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress(
                displayName: "John Doe",
                localPart: .init("john"),
                domain: .init("example.com")
            ),
            to: [try RFC_5322.EmailAddress("jane@example.com")],
            subject: "Hello from Swift!",
            date: Date(),
            messageId: "<test@example.com>",
            body: Data("Hello, World!".utf8)
        )

        let emlContent = message.render()
        #expect(emlContent.contains("From: John Doe <john@example.com>"))
        #expect(emlContent.contains("To: jane@example.com"))
        #expect(emlContent.contains("Subject: Hello from Swift!"))
        #expect(emlContent.contains("Message-ID: <test@example.com>"))
        #expect(emlContent.contains("Hello, World!"))
    }

    @Test("README Line 107-122: Advanced message features")
    func advancedMessageFeatures() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            cc: [try RFC_5322.EmailAddress("cc@example.com")],
            bcc: [try RFC_5322.EmailAddress("bcc@example.com")],
            replyTo: try RFC_5322.EmailAddress("replyto@example.com"),
            subject: "Meeting Notes",
            date: Date(),
            messageId: "<unique-id@example.com>",
            body: Data("Meeting summary...".utf8),
            additionalHeaders: [
                RFC_5322.Header(name: RFC_5322.Header.Name("X-Priority"), value: "1"),
                RFC_5322.Header(name: .contentType, value: "text/plain; charset=utf-8"),
            ]
        )

        #expect(message.cc?.count == 1)
        #expect(message.bcc?.count == 1)
        #expect(message.replyTo?.addressValue == "replyto@example.com")
        #expect(message.additionalHeaders.count == 2)
    }

    @Test("README Line 128-129: Format date")
    func formatDate() throws {
        let dateString = RFC_5322.Date.string(from: Date())
        #expect(!dateString.isEmpty)
        // Should contain day, month, year, time
        #expect(dateString.contains(","))
    }
}
