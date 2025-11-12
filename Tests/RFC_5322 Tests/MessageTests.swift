//
//  MessageTests.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 12/11/2025.
//

import Foundation
import Testing
@testable import RFC_5322

@Suite("RFC 5322 Message Tests")
struct MessageTests {

    @Test("Create basic message")
    func createBasicMessage() throws {
        let from = try RFC_5322.EmailAddress("sender@example.com")
        let to = [try RFC_5322.EmailAddress("recipient@example.com")]

        let message = RFC_5322.Message(
            from: from,
            to: to,
            subject: "Test Message",
            date: Date(),
            messageId: "<test@example.com>",
            body: "Hello, World!"
        )

        let rendered = message.render()

        #expect(rendered.contains("From: sender@example.com"))
        #expect(rendered.contains("To: recipient@example.com"))
        #expect(rendered.contains("Subject: Test Message"))
        #expect(rendered.contains("Hello, World!"))
    }
}
