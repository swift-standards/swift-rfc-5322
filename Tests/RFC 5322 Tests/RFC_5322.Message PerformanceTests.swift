//
//  RFC_5322.Message PerformanceTests.swift
//  RFC 5322 Tests
//
//  Performance tests for RFC_5322.Message
//

import Testing
import StandardsTestSupport
@testable import RFC_5322

extension PerformanceTests {
    @Suite(.serialized)
    struct `RFC_5322.Message` {

        // MARK: - Message Rendering Performance

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(380)))
        func `render basic message to string`() throws {
            let message = RFC_5322.Message(
                from: try RFC_5322.EmailAddress("sender@example.com"),
                to: [try RFC_5322.EmailAddress("recipient@example.com")],
                date: .init(),
                subject: "Test",
                messageId: "<test@example.com>",
                body: Array("Hello, World!".utf8)
            )
            _ = String(message)
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(650)))
        func `render message with multiple recipients`() throws {
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
                body: Array("Hello everyone!".utf8)
            )
            _ = String(message)
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(750)))
        func `render message with all optional fields`() throws {
            let message = RFC_5322.Message(
                from: try RFC_5322.EmailAddress("sender@example.com"),
                to: [try RFC_5322.EmailAddress("recipient@example.com")],
                cc: [try RFC_5322.EmailAddress("cc@example.com")],
                bcc: [try RFC_5322.EmailAddress("bcc@example.com")],
                replyTo: try RFC_5322.EmailAddress("replyto@example.com"),
                date: .init(),
                subject: "Full Message",
                messageId: "<full@example.com>",
                body: Array("Test body".utf8),
                additionalHeaders: [
                    RFC_5322.Header(name: "X-Priority", value: "1")
                ]
            )
            _ = String(message)
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(420)))
        func `render message with large body`() throws {
            let largeBody = String(repeating: "This is a test message. ", count: 100)
            let message = RFC_5322.Message(
                from: try RFC_5322.EmailAddress("sender@example.com"),
                to: [try RFC_5322.EmailAddress("recipient@example.com")],
                date: .init(),
                subject: "Large Message",
                messageId: "<large@example.com>",
                body: Array(largeBody.utf8)
            )
            _ = String(message)
        }

        // MARK: - Byte Conversion Performance

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(370)))
        func `convert basic message to bytes`() throws {
            let message = RFC_5322.Message(
                from: try RFC_5322.EmailAddress("sender@example.com"),
                to: [try RFC_5322.EmailAddress("recipient@example.com")],
                date: .init(),
                subject: "Test",
                messageId: "<test@example.com>",
                body: Array("Hello".utf8)
            )
            _ = [UInt8](message)
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(420)))
        func `convert message with large body to bytes`() throws {
            let largeBody = String(repeating: "Test data. ", count: 200)
            let message = RFC_5322.Message(
                from: try RFC_5322.EmailAddress("sender@example.com"),
                to: [try RFC_5322.EmailAddress("recipient@example.com")],
                date: .init(),
                subject: "Large",
                messageId: "<large@example.com>",
                body: Array(largeBody.utf8)
            )
            _ = [UInt8](message)
        }

        // MARK: - Message ID Generation Performance

        @Test(
            .timed(iterations: 10000, warmup: 1000, threshold: .microseconds(100)),
            arguments: [try! RFC_5322.EmailAddress("sender@example.com")]
        )
        func `generate message ID`(from: RFC_5322.EmailAddress) {
            _ = RFC_5322.Message.generateMessageId(
                from: from,
                uniqueId: "test-unique-id-123"
            )
        }
    }
}
