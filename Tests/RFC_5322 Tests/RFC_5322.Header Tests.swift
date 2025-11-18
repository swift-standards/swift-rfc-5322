//
//  RFC_5322.Header Tests.swift
//  RFC 5322 Tests
//
//  Tests for RFC_5322.Header including creation, validation, and array extensions
//

import Testing
@testable import RFC_5322

@Suite("RFC_5322.Header")
struct RFC_5322_Header_Tests {

    // MARK: - Header Creation

    @Test("Create header with standard name")
    func createHeaderWithStandardName() {
        let header = RFC_5322.Header(name: .contentType, value: "text/plain")

        #expect(header.name == .contentType)
        #expect(header.value == "text/plain")
    }

    @Test("Create header with custom name")
    func createHeaderWithCustomName() {
        let header = RFC_5322.Header(name: "X-Custom-Header", value: "custom value")

        #expect(header.name.rawValue == "X-Custom-Header")
        #expect(header.value == "custom value")
    }

    // MARK: - Header Name Tests

    @Test("Header names are case-insensitive for equality")
    func headerNamesCaseInsensitive() {
        let name1 = RFC_5322.Header.Name("Content-Type")
        let name2 = RFC_5322.Header.Name("content-type")
        let name3 = RFC_5322.Header.Name("CONTENT-TYPE")

        #expect(name1 == name2)
        #expect(name2 == name3)
        #expect(name1 == name3)
    }

    @Test("Header names preserve original case")
    func headerNamesPreserveCase() {
        let name = RFC_5322.Header.Name("X-Custom-Header")

        #expect(name.rawValue == "X-Custom-Header")
        #expect(name.description == "X-Custom-Header")
    }

    @Test("Standard header names are defined")
    func standardHeaderNamesExist() {
        #expect(RFC_5322.Header.Name.from.rawValue == "From")
        #expect(RFC_5322.Header.Name.to.rawValue == "To")
        #expect(RFC_5322.Header.Name.subject.rawValue == "Subject")
        #expect(RFC_5322.Header.Name.date.rawValue == "Date")
        #expect(RFC_5322.Header.Name.messageId.rawValue == "Message-ID")
        #expect(RFC_5322.Header.Name.contentType.rawValue == "Content-Type")
    }

    @Test("Header name from string literal")
    func headerNameFromStringLiteral() {
        let name: RFC_5322.Header.Name = "X-Test"

        #expect(name.rawValue == "X-Test")
    }

    // MARK: - Header Description

    @Test("Header description format")
    func headerDescriptionFormat() {
        let header = RFC_5322.Header(name: "X-Test", value: "test value")
        let description = header.description

        #expect(description == "X-Test: test value")
    }

    @Test("Header with colon in value")
    func headerWithColonInValue() {
        let header = RFC_5322.Header(
            name: .contentType,
            value: "text/plain; charset=utf-8"
        )

        #expect(header.description == "Content-Type: text/plain; charset=utf-8")
    }

    // MARK: - Array Extensions - Subscript

    @Test("Array subscript get header value")
    func arraySubscriptGet() {
        var headers = [RFC_5322.Header]()
        headers.append(RFC_5322.Header(name: .contentType, value: "text/plain"))

        #expect(headers[.contentType] == "text/plain")
    }

    @Test("Array subscript returns nil for missing header")
    func arraySubscriptMissing() {
        let headers = [RFC_5322.Header]()

        #expect(headers[.contentType] == nil)
    }

    @Test("Array subscript set header value")
    func arraySubscriptSet() {
        var headers = [RFC_5322.Header]()
        headers[.contentType] = "text/html"

        #expect(headers.count == 1)
        #expect(headers[0].name == .contentType)
        #expect(headers[0].value == "text/html")
    }

    @Test("Array subscript set replaces existing header")
    func arraySubscriptSetReplaces() {
        var headers = [RFC_5322.Header]()
        headers.append(RFC_5322.Header(name: .contentType, value: "text/plain"))
        headers[.contentType] = "text/html"

        #expect(headers.count == 1)
        #expect(headers[0].value == "text/html")
    }

    @Test("Array subscript set nil removes header")
    func arraySubscriptSetNilRemoves() {
        var headers = [RFC_5322.Header]()
        headers.append(RFC_5322.Header(name: .contentType, value: "text/plain"))
        headers[.contentType] = nil

        #expect(headers.count == 0)
    }

    @Test("Array subscript removes all headers with same name")
    func arraySubscriptRemovesAll() {
        var headers = [RFC_5322.Header]()
        headers.append(RFC_5322.Header(name: .received, value: "server1"))
        headers.append(RFC_5322.Header(name: .received, value: "server2"))
        headers[.received] = "server3"

        // Should remove both old headers and add one new one
        #expect(headers.count == 1)
        #expect(headers[0].value == "server3")
    }

    // MARK: - Array Extensions - all()

    @Test("Array all() returns multiple headers with same name")
    func arrayAllMultipleHeaders() {
        var headers = [RFC_5322.Header]()
        headers.append(RFC_5322.Header(name: .received, value: "server1"))
        headers.append(RFC_5322.Header(name: .received, value: "server2"))
        headers.append(RFC_5322.Header(name: .contentType, value: "text/plain"))

        let received = headers.all(.received)

        #expect(received.count == 2)
        #expect(received[0].value == "server1")
        #expect(received[1].value == "server2")
    }

    @Test("Array all() returns empty for missing header")
    func arrayAllEmpty() {
        let headers = [RFC_5322.Header]()
        let received = headers.all(.received)

        #expect(received.count == 0)
    }

    // MARK: - Array Extensions - values(for:)

    @Test("Array values(for:) returns header values")
    func arrayValuesFor() {
        var headers = [RFC_5322.Header]()
        headers.append(RFC_5322.Header(name: .received, value: "server1"))
        headers.append(RFC_5322.Header(name: .received, value: "server2"))

        let values = headers.values(for: .received)

        #expect(values.count == 2)
        #expect(values[0] == "server1")
        #expect(values[1] == "server2")
    }

    // MARK: - Dictionary Literal

    @Test("Create headers from dictionary literal")
    func createFromDictionaryLiteral() {
        let headers: [RFC_5322.Header] = [
            .from: "sender@example.com",
            .to: "recipient@example.com",
            .subject: "Test"
        ]

        #expect(headers.count == 3)
        #expect(headers[.from] == "sender@example.com")
        #expect(headers[.to] == "recipient@example.com")
        #expect(headers[.subject] == "Test")
    }

    // MARK: - Hashable

    @Test("Headers with same name and value are equal")
    func headersEqual() {
        let header1 = RFC_5322.Header(name: .contentType, value: "text/plain")
        let header2 = RFC_5322.Header(name: .contentType, value: "text/plain")

        #expect(header1 == header2)
    }

    @Test("Headers with different values are not equal")
    func headersDifferentValues() {
        let header1 = RFC_5322.Header(name: .contentType, value: "text/plain")
        let header2 = RFC_5322.Header(name: .contentType, value: "text/html")

        #expect(header1 != header2)
    }

    @Test("Headers with case-insensitive names are equal")
    func headersCaseInsensitiveNames() {
        let header1 = RFC_5322.Header(name: "X-Test", value: "value")
        let header2 = RFC_5322.Header(name: "x-test", value: "value")

        // Names are case-insensitive
        #expect(header1.name == header2.name)
    }

    // MARK: - Common Headers

    @Test("RFC 5322 standard headers exist")
    func rfc5322StandardHeaders() {
        #expect(RFC_5322.Header.Name.from.rawValue == "From")
        #expect(RFC_5322.Header.Name.to.rawValue == "To")
        #expect(RFC_5322.Header.Name.cc.rawValue == "Cc")
        #expect(RFC_5322.Header.Name.bcc.rawValue == "Bcc")
        #expect(RFC_5322.Header.Name.replyTo.rawValue == "Reply-To")
        #expect(RFC_5322.Header.Name.sender.rawValue == "Sender")
        #expect(RFC_5322.Header.Name.inReplyTo.rawValue == "In-Reply-To")
        #expect(RFC_5322.Header.Name.references.rawValue == "References")
    }

    @Test("MIME headers exist")
    func mimeHeadersExist() {
        #expect(RFC_5322.Header.Name.contentType.rawValue == "Content-Type")
        #expect(RFC_5322.Header.Name.contentTransferEncoding.rawValue == "Content-Transfer-Encoding")
        #expect(RFC_5322.Header.Name.mimeVersion.rawValue == "MIME-Version")
        #expect(RFC_5322.Header.Name.contentDisposition.rawValue == "Content-Disposition")
    }

    @Test("Extension headers exist")
    func extensionHeadersExist() {
        #expect(RFC_5322.Header.Name.xMailer.rawValue == "X-Mailer")
        #expect(RFC_5322.Header.Name.xPriority.rawValue == "X-Priority")
        #expect(RFC_5322.Header.Name.listUnsubscribe.rawValue == "List-Unsubscribe")
    }
}
