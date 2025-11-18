//
//  RFC_5322.EmailAddress Tests.swift
//  RFC 5322 Tests
//
//  Tests for RFC_5322.EmailAddress including parsing, validation, and formatting
//

import RFC_5322
import Testing

@Suite("RFC_5322.EmailAddress")
struct RFC_5322_EmailAddress_Tests {

    // MARK: - Parsing Tests

    @Test("Parse simple email address")
    func parseSimpleAddress() throws {
        let email = try RFC_5322.EmailAddress("user@example.com")
        #expect(email.localPart.description == "user")
        #expect(email.domain.name == "example.com")
        #expect(email.displayName == nil)
    }

    @Test("Parse email with display name")
    func parseWithDisplayName() throws {
        let email = try RFC_5322.EmailAddress("John Doe <john@example.com>")
        #expect(email.displayName == "John Doe")
        #expect(email.localPart.description == "john")
        #expect(email.domain.name == "example.com")
        #expect(email.addressValue == "john@example.com")
    }

    @Test("Parse email with quoted display name")
    func parseQuotedDisplayName() throws {
        let email = try RFC_5322.EmailAddress("\"Doe, John\" <john@example.com>")
        #expect(email.displayName == "Doe, John")
        #expect(email.addressValue == "john@example.com")
    }

    // MARK: - Creation from Components

    @Test("Create from components without display name")
    func createFromComponentsWithoutDisplayName() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: nil,
            localPart: .init("user"),
            domain: .init("example.com")
        )
        #expect(email.displayName == nil)
        #expect(email.localPart.description == "user")
        #expect(email.domain.name == "example.com")
    }

    @Test("Create from components with display name")
    func createFromComponentsWithDisplayName() throws {
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

    @Test("All RFC 5322 atext special characters are accepted")
    func allAtextCharsAccepted() throws {
        // RFC 5322 Section 3.2.3 defines atext as:
        // atext = ALPHA / DIGIT / "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" / "`" / "{" / "|" / "}" / "~"

        let specialChars = "!#$%&'*+-/=?^_`{|}~"

        // Test each character individually
        for char in specialChars {
            let email = try RFC_5322.EmailAddress("test\(char)user@example.com")
            #expect(email.localPart.description.contains(char))
        }
    }

    @Test("Exclamation mark (!) is accepted in local-part")
    func exclamationMarkAccepted() throws {
        let email = try RFC_5322.EmailAddress("user!tag@example.com")
        #expect(email.localPart.description == "user!tag")
        #expect(email.addressValue == "user!tag@example.com")
    }

    @Test("Pipe character (|) is accepted in local-part")
    func pipeCharacterAccepted() throws {
        let email = try RFC_5322.EmailAddress("user|tag@example.com")
        #expect(email.localPart.description == "user|tag")
        #expect(email.addressValue == "user|tag@example.com")
    }

    @Test("All atext characters together in local-part")
    func allCharsTogetherAccepted() throws {
        let allChars = "test!#$%&'*+-/=?^_`{|}~user"
        let email = try RFC_5322.EmailAddress("\(allChars)@example.com")
        #expect(email.localPart.description == allChars)
    }

    @Test("Multiple atext special characters in same address")
    func multipleSpecialChars() throws {
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
            #expect(email.addressValue == address)
        }
    }

    // MARK: - String Formatting

    @Test("Format email without display name")
    func formatWithoutDisplayName() throws {
        let email = try RFC_5322.EmailAddress("user@example.com")
        let formatted = String(email)
        #expect(formatted == "user@example.com")
    }

    @Test("Format email with display name")
    func formatWithDisplayName() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: "John Doe",
            localPart: .init("john"),
            domain: .init("example.com")
        )
        let formatted = String(email)
        #expect(formatted == "John Doe <john@example.com>")
    }

    @Test("Format email with display name requiring quotes")
    func formatDisplayNameNeedingQuotes() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: "Doe, John",
            localPart: .init("john"),
            domain: .init("example.com")
        )
        let formatted = String(email)
        #expect(formatted == "\"Doe, John\" <john@example.com>")
    }

    // MARK: - addressValue Property

    @Test("addressValue returns email without display name")
    func addressValueProperty() throws {
        let email = try RFC_5322.EmailAddress(
            displayName: "John Doe",
            localPart: .init("john"),
            domain: .init("example.com")
        )
        #expect(email.addressValue == "john@example.com")
    }

    // MARK: - Validation Errors

    @Test("Reject email without @ sign")
    func rejectMissingAtSign() throws {
        #expect(throws: RFC_5322.EmailAddress.ValidationError.self) {
            _ = try RFC_5322.EmailAddress("userexample.com")
        }
    }

    @Test("Reject consecutive dots in local-part")
    func rejectConsecutiveDots() throws {
        #expect(throws: RFC_5322.EmailAddress.ValidationError.self) {
            _ = try RFC_5322.EmailAddress("user..name@example.com")
        }
    }

    @Test("Reject leading dot in local-part")
    func rejectLeadingDot() throws {
        #expect(throws: RFC_5322.EmailAddress.ValidationError.self) {
            _ = try RFC_5322.EmailAddress(".user@example.com")
        }
    }

    @Test("Reject trailing dot in local-part")
    func rejectTrailingDot() throws {
        #expect(throws: RFC_5322.EmailAddress.ValidationError.self) {
            _ = try RFC_5322.EmailAddress("user.@example.com")
        }
    }

    @Test("Reject local-part exceeding 64 characters")
    func rejectTooLongLocalPart() throws {
        let longLocalPart = String(repeating: "a", count: 65)
        #expect(throws: RFC_5322.EmailAddress.ValidationError.localPartTooLong(65)) {
            _ = try RFC_5322.EmailAddress("\(longLocalPart)@example.com")
        }
    }
}
