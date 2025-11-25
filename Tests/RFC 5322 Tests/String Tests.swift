//
//  String Tests.swift
//  RFC 5322 Tests
//
//  Tests for String extension initializers
//

import Testing
@testable import RFC_5322

@Suite
struct `String Tests` {

    // MARK: - EmailAddress to String

    @Test
    func `Convert simple email to string`() throws {
        let email = try RFC_5322.EmailAddress("user@example.com")
        let string = String(email)

        #expect(string == "user@example.com")
    }

    @Test
    func `Convert email with display name to string`() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: "John Doe",
            localPart: .init("john"),
            domain: .init("example.com")
        )
        let string = String(email)

        #expect(string == "John Doe <john@example.com>")
    }

    @Test
    func `Convert email with quoted display name to string`() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: "Doe, John",
            localPart: .init("john"),
            domain: .init("example.com")
        )
        let string = String(email)

        #expect(string == "\"Doe, John\" <john@example.com>")
    }

    @Test
    func `Display name with special characters gets quoted`() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: "John@Doe",
            localPart: .init("john"),
            domain: .init("example.com")
        )
        let string = String(email)

        #expect(string.hasPrefix("\""))
        #expect(string.contains("John@Doe"))
    }

    // MARK: - Message to String

    @Test
    func `Convert message to string`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Hello".utf8)
        )

        let string = String(message)

        #expect(string.contains("From: sender@example.com"))
        #expect(string.contains("To: recipient@example.com"))
        #expect(string.contains("Subject: Test"))
        #expect(string.contains("Hello"))
    }

    @Test
    func `String conversion matches byte conversion`() throws {
        let message = RFC_5322.Message(
            from: try RFC_5322.EmailAddress("sender@example.com"),
            to: [try RFC_5322.EmailAddress("recipient@example.com")],
            date: .init(secondsSinceEpoch: 0),
            subject: "Test",
            messageId: "<test@example.com>",
            body: Array("Test".utf8)
        )

        let fromString = String(message)
        let fromBytes = String(decoding: [UInt8](message), as: UTF8.self)

        #expect(fromString == fromBytes)
    }

    // MARK: - DateTime to String

    @Test
    func `Convert datetime to string`() throws {
        let dateTime = try RFC_5322.DateTime(
            year: 2024,
            month: 1,
            day: 15,
            hour: 12,
            minute: 30
        )

        let string = String(dateTime)

        #expect(!string.isEmpty)
        #expect(string.contains(","))
        #expect(string.contains(":"))
    }

    @Test
    func `DateTime string matches description`() {
        let dateTime = RFC_5322.DateTime(secondsSinceEpoch: 1609459200)

        #expect(String(dateTime) == dateTime.description)
    }

    // MARK: - Header to String

    @Test
    func `Convert header to string`() throws {
        let header = try RFC_5322.Header(name: .subject, value: .init("Hello World"))
        let string = String(decoding: [UInt8](header), as: UTF8.self)

        #expect(string == "Subject: Hello World")
    }

    @Test
    func `Header string format`() throws {
        let header = try RFC_5322.Header(name: .init("X-Test"), value: .init("test value"))
        let string = String(decoding: [UInt8](header), as: UTF8.self)

        #expect(string == "X-Test: test value")
        #expect(string.contains(": "))
    }
}
