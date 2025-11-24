//
//  RFC_5322.Header Tests.swift
//  RFC 5322 Tests
//
//  Tests for RFC_5322.Header including creation, validation, and array extensions
//

import Testing
import INCITS_4_1986
@testable import RFC_5322

@Suite
struct `RFC_5322.Header Tests` {

    // MARK: - Header Creation

    @Test
    func `Create header with standard name`() throws {
        let header = try RFC_5322.Header(name: .subject, value: .init("text/plain"))

        #expect(header.name == .subject)
        #expect(header.value == "text/plain")
    }

    @Test
    func `Create header with custom name`() throws {
        let header = try RFC_5322.Header(name: .init("X-Custom-Header"), value: .init("custom value"))

        #expect(header.name.rawValue == "X-Custom-Header")
        #expect(header.value == "custom value")
    }

    // MARK: - Header Name Tests

    @Test
    func `Header names are case-insensitive for equality`() throws {
        let name1 = try RFC_5322.Header.Name("Content-Type")
        let name2 = try RFC_5322.Header.Name("content-type")
        let name3 = try RFC_5322.Header.Name("CONTENT-TYPE")

        #expect(name1 == name2)
        #expect(name2 == name3)
        #expect(name1 == name3)
    }

    @Test
    func `Header names preserve original case`() throws {
        let name = try RFC_5322.Header.Name("X-Custom-Header")

        #expect(name.rawValue == "X-Custom-Header")
        #expect(name.description == "X-Custom-Header")
    }

    @Test
    func `Standard header names are defined`() throws {
        #expect(RFC_5322.Header.Name.from.rawValue == "From")
        #expect(RFC_5322.Header.Name.to.rawValue == "To")
        #expect(RFC_5322.Header.Name.subject.rawValue == "Subject")
        #expect(RFC_5322.Header.Name.date.rawValue == "Date")
        #expect(RFC_5322.Header.Name.messageId.rawValue == "Message-ID")
        #expect(RFC_5322.Header.Name.inReplyTo.rawValue == "In-Reply-To")
    }

    @Test
    func `Header name from string literal`() throws {
        let name: RFC_5322.Header.Name = try .init("X-Test")

        #expect(name.rawValue == "X-Test")
    }

    // MARK: - Header Description

    @Test
    func `Header description format`() throws {
        let header = try RFC_5322.Header(name: .init("X-Test"), value: .init("test value"))
        let description = header.description

        #expect(description == "X-Test: test value")
    }

    @Test
    func `Header with semicolon in value`() throws {
        let header = try RFC_5322.Header(
            name: .subject,
            value: .init("RE: Meeting; Notes")
        )

        #expect(header.description == "Subject: RE: Meeting; Notes")
    }

    // MARK: - Array Extensions - Subscript

    @Test
    func `Array subscript get header value`() throws {
        var headers = [RFC_5322.Header]()
        headers.append(try RFC_5322.Header(name: .subject, value: .init("text/plain")))

        #expect(headers[.subject] == "text/plain")
    }

    @Test
    func `Array subscript returns nil for missing header`() throws {
        let headers = [RFC_5322.Header]()

        #expect(headers[.subject] == nil)
    }

    @Test
    func `Array subscript set header value`() throws {
        var headers = [RFC_5322.Header]()
        headers[.subject] = "text/html"

        #expect(headers.count == 1)
        #expect(headers[0].name == .subject)
        #expect(headers[0].value == "text/html")
    }

    @Test
    func `Array subscript set replaces existing header`() throws {
        var headers = [RFC_5322.Header]()
        headers.append(try RFC_5322.Header(name: .subject, value: .init("text/plain")))
        headers[.subject] = "text/html"

        #expect(headers.count == 1)
        #expect(headers[0].value == "text/html")
    }

    @Test
    func `Array subscript set nil removes header`() throws {
        var headers = [RFC_5322.Header]()
        headers.append(try RFC_5322.Header(name: .subject, value: .init("text/plain")))
        headers[.subject] = nil

        #expect(headers.count == 0)
    }

    @Test
    func `Array subscript removes all headers with same name`() throws {
        var headers = [RFC_5322.Header]()
        headers.append(try RFC_5322.Header(name: .received, value: .init("server1")))
                       headers.append(try RFC_5322.Header(name: .received, value: .init("server2")))
        headers[.received] = "server3"

        // Should remove both old headers and add one new one
        #expect(headers.count == 1)
        #expect(headers[0].value == "server3")
    }

    // MARK: - Array Extensions - all()

    @Test
    func `Array all() returns multiple headers with same name`() throws {
        var headers = [RFC_5322.Header]()
        headers.append(try RFC_5322.Header(name: .received, value: .init("server1")))
                       headers.append(try RFC_5322.Header(name: .received, value: .init("server2")))
                                      headers.append(try RFC_5322.Header(name: .subject, value: .init("text/plain")))

        let received = headers.all(.received)

        #expect(received.count == 2)
        #expect(received[0].value == "server1")
        #expect(received[1].value == "server2")
    }

    @Test
    func `Array all() returns empty for missing header`() throws {
        let headers = [RFC_5322.Header]()
        let received = headers.all(.received)

        #expect(received.count == 0)
    }

    // MARK: - Array Extensions - values(for:)

    @Test
    func `Array values(for:) returns header values`() throws {
        var headers = [RFC_5322.Header]()
        headers.append(try RFC_5322.Header(name: .received, value: .init("server1")))
                       headers.append(try RFC_5322.Header(name: .received, value: .init("server2")))

        let values = headers.values(for: .received)

        #expect(values.count == 2)
        #expect(values[0] == "server1")
        #expect(values[1] == "server2")
    }

    // MARK: - Dictionary Literal

    @Test
    func `Create headers from dictionary literal`() throws {
        let headers: [RFC_5322.Header] = try [
            .from: .init("sender@example.com"),
            .to: .init("recipient@example.com"),
            .subject: .init("Test")
        ]

        #expect(headers.count == 3)
        #expect(headers[.from] == "sender@example.com")
        #expect(headers[.to] == "recipient@example.com")
        #expect(headers[.subject] == "Test")
    }

    // MARK: - Hashable

    @Test
    func `Headers with same name and value are equal`() throws {
        let header1 = try RFC_5322.Header(name: .subject, value: .init("text/plain"))
        let header2 = try RFC_5322.Header(name: .subject, value: .init("text/plain"))

        #expect(header1 == header2)
    }

    @Test
    func `Headers with different values are not equal`() throws {
        let header1 = try RFC_5322.Header(name: .subject, value: .init("text/plain"))
        let header2 = try RFC_5322.Header(name: .subject, value: .init("text/html"))

        #expect(header1 != header2)
    }

    @Test
    func `Headers with case-insensitive names are equal`() throws {
        let header1 = try RFC_5322.Header(name: .init("X-Test"), value: .init("value"))
        let header2 = try RFC_5322.Header(name: .init("x-test"), value: .init("value"))

        // Names are case-insensitive
        #expect(header1.name == header2.name)
    }

    // MARK: - Common Headers

    @Test
    func `RFC 5322 standard headers exist`() throws {
        #expect(RFC_5322.Header.Name.from.rawValue == "From")
        #expect(RFC_5322.Header.Name.to.rawValue == "To")
        #expect(RFC_5322.Header.Name.cc.rawValue == "Cc")
        #expect(RFC_5322.Header.Name.bcc.rawValue == "Bcc")
        #expect(RFC_5322.Header.Name.replyTo.rawValue == "Reply-To")
        #expect(RFC_5322.Header.Name.sender.rawValue == "Sender")
        #expect(RFC_5322.Header.Name.inReplyTo.rawValue == "In-Reply-To")
        #expect(RFC_5322.Header.Name.references.rawValue == "References")
    }

    @Test
    func `Extension headers exist`() throws {
        #expect(RFC_5322.Header.Name.xMailer.rawValue == "X-Mailer")
        #expect(RFC_5322.Header.Name.xPriority.rawValue == "X-Priority")
        #expect(RFC_5322.Header.Name.listUnsubscribe.rawValue == "List-Unsubscribe")
    }
}
