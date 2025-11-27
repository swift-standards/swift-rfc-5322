//
//  RFC_5322.EmailAddress PerformanceTests.swift
//  RFC 5322 Tests
//
//  Performance tests for RFC_5322.EmailAddress
//

import StandardsTestSupport
import Testing

@testable import RFC_5322

extension PerformanceTests {
    @Suite
    struct `RFC_5322.EmailAddress` {

        // MARK: - Parsing Performance

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(230)))
        func `parse simple email address`() throws {
            _ = try RFC_5322.EmailAddress("user@example.com")
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(250)))
        func `parse email with display name`() throws {
            _ = try RFC_5322.EmailAddress("John Doe <john@example.com>")
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(250)))
        func `parse email with quoted display name`() throws {
            _ = try RFC_5322.EmailAddress("\"Doe, John\" <john@example.com>")
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(230)))
        func `parse email with atext special characters`() throws {
            _ = try RFC_5322.EmailAddress("user!tag+value@example.com")
        }

        // MARK: - Construction Performance

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(105)))
        func `create from components without display name`() throws {
            _ = try RFC_5322.EmailAddress(
                displayName: nil,
                localPart: .init("user"),
                domain: .init("example.com")
            )
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(105)))
        func `create from components with display name`() throws {
            _ = try RFC_5322.EmailAddress(
                displayName: "John Doe",
                localPart: .init("john"),
                domain: .init("example.com")
            )
        }

        // MARK: - Formatting Performance

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(230)))
        func `format to string without display name`() throws {
            let email = try RFC_5322.EmailAddress("user@example.com")
            _ = String(email)
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(110)))
        func `format to string with display name`() throws {
            let email = try RFC_5322.EmailAddress(
                displayName: "John Doe",
                localPart: .init("john"),
                domain: .init("example.com")
            )
            _ = String(email)
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(110)))
        func `format to string with quoting needed`() throws {
            let email = try RFC_5322.EmailAddress(
                displayName: "Doe, John",
                localPart: .init("john"),
                domain: .init("example.com")
            )
            _ = String(email)
        }

        // MARK: - Byte Conversion Performance

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(240)))
        func `convert to bytes without display name`() throws {
            let email = try RFC_5322.EmailAddress("user@example.com")
            _ = [UInt8](email)
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(110)))
        func `convert to bytes with display name`() throws {
            let email = try RFC_5322.EmailAddress(
                displayName: "John Doe",
                localPart: .init("john"),
                domain: .init("example.com")
            )
            _ = [UInt8](email)
        }
    }
}
