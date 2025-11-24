//
//  RFC_5322.EmailAddress Tests.swift
//  RFC 5322 Tests
//
//  Tests for RFC_5322.EmailAddress including parsing, validation, and formatting
//

import RFC_5322
import Testing

@Suite
struct `RFC_5322.EmailAddress Tests` {

    // MARK: - Parsing Tests

    @Test
    func `Parse simple email address`() throws {
        let email = try RFC_5322.EmailAddress("user@example.com")
        #expect(email.localPart.description == "user")
        #expect(email.domain.name == "example.com")
        #expect(email.displayName == nil)
    }

    @Test
    func `Parse email with display name`() throws {
        let email = try RFC_5322.EmailAddress("John Doe <john@example.com>")
        #expect(email.displayName == "John Doe")
        #expect(email.localPart.description == "john")
        #expect(email.domain.name == "example.com")
        #expect(email.address == "john@example.com")
    }

    @Test
    func `Parse email with quoted display name`() throws {
        let email = try RFC_5322.EmailAddress("\"Doe, John\" <john@example.com>")
        #expect(email.displayName == "Doe, John")
        #expect(email.address == "john@example.com")
    }

    // MARK: - Creation from Components

    @Test
    func `Create from components without display name`() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: nil,
            localPart: .init("user"),
            domain: .init("example.com")
        )
        #expect(email.displayName == nil)
        #expect(email.localPart.description == "user")
        #expect(email.domain.name == "example.com")
    }

    @Test
    func `Create from components with display name`() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: "Jane Smith",
            localPart: .init("jane"),
            domain: .init("example.com")
        )
        #expect(email.displayName == "Jane Smith")
        #expect(email.localPart.description == "jane")
        #expect(email.domain.name == "example.com")
    }

    // MARK: - RFC 5322 atext Character Validation

    @Test
    func `All RFC 5322 atext special characters are accepted`() throws {
        // RFC 5322 Section 3.2.3 defines atext as:
        // atext = ALPHA / DIGIT / "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" / "`" / "{" / "|" / "}" / "~"

        let specialChars = "!#$%&'*+-/=?^_`{|}~"

        // Test each character individually
        for char in specialChars {
            let email = try RFC_5322.EmailAddress("test\(char)user@example.com")
            #expect(email.localPart.description.contains(char))
        }
    }

    @Test
    func `Exclamation mark (!) is accepted in local-part`() throws {
        let email = try RFC_5322.EmailAddress("user!tag@example.com")
        #expect(email.localPart.description == "user!tag")
        #expect(email.address == "user!tag@example.com")
    }

    @Test
    func `Pipe character (|) is accepted in local-part`() throws {
        let email = try RFC_5322.EmailAddress("user|tag@example.com")
        #expect(email.localPart.description == "user|tag")
        #expect(email.address == "user|tag@example.com")
    }

    @Test
    func `All atext characters together in local-part`() throws {
        let allChars = "test!#$%&'*+-/=?^_`{|}~user"
        let email = try RFC_5322.EmailAddress("\(allChars)@example.com")
        #expect(email.localPart.description == allChars)
    }

    @Test
    func `Multiple atext special characters in same address`() throws {
        // Test addresses with multiple special characters
        let testAddresses = [
            "user!tag@example.com",
            "user|tag@example.com",
            "test#value@example.com",
            "name+tag@example.com",
            "user=value@example.com",
            "test!user|tag@example.com"
        ]

        for address in testAddresses {
            let email = try RFC_5322.EmailAddress(address)
            #expect(email.address == address)
        }
    }

    // MARK: - String Formatting

    @Test
    func `Format email without display name`() throws {
        let email = try RFC_5322.EmailAddress("user@example.com")
        let formatted = String(email)
        #expect(formatted == "user@example.com")
    }

    @Test
    func `Format email with display name`() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: "John Doe",
            localPart: .init("john"),
            domain: .init("example.com")
        )
        let formatted = String(email)
        #expect(formatted == "John Doe <john@example.com>")
    }

    @Test
    func `Format email with display name requiring quotes`() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: "Doe, John",
            localPart: .init("john"),
            domain: .init("example.com")
        )
        let formatted = String(email)
        #expect(formatted == "\"Doe, John\" <john@example.com>")
    }

    // MARK: - address Property

    @Test
    func `address returns email without display name`() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: "John Doe",
            localPart: .init("john"),
            domain: .init("example.com")
        )
        #expect(email.address == "john@example.com")
    }

    // MARK: - Validation Errors

    @Test
    func `Reject email without @ sign`() throws {
        #expect(throws: RFC_5322.EmailAddress.Error.self) {
            _ = try RFC_5322.EmailAddress("userexample.com")
        }
    }

    @Test
    func `Reject consecutive dots in local-part`() throws {
        #expect(throws: RFC_5322.EmailAddress.Error.self) {
            _ = try RFC_5322.EmailAddress("user..name@example.com")
        }
    }

    @Test
    func `Reject leading dot in local-part`() throws {
        #expect(throws: RFC_5322.EmailAddress.Error.self) {
            _ = try RFC_5322.EmailAddress(".user@example.com")
        }
    }

    @Test
    func `Reject trailing dot in local-part`() throws {
        #expect(throws: RFC_5322.EmailAddress.Error.self) {
            _ = try RFC_5322.EmailAddress("user.@example.com")
        }
    }

    @Test
    func `Reject local-part exceeding 64 characters`() throws {
        let longLocalPart = String(repeating: "a", count: 65)
        #expect(throws: RFC_5322.EmailAddress.Error.localPart(.tooLong(65))) {
            _ = try RFC_5322.EmailAddress("\(longLocalPart)@example.com")
        }
    }
}
