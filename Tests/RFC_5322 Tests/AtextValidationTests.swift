//
//  AtextValidationTests.swift
//  RFC 5322 Tests
//
//  Tests to verify RFC 5322 Section 3.2.3 atext character support
//

import Foundation
import RFC_5322
import Testing

@Suite("atext Character Validation")
struct AtextValidationTests {

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
}
