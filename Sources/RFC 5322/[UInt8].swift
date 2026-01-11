//
//  [UInt8].swift
//  swift-rfc-5322
//
//  Type conversions for RFC 5322 Message
//

import INCITS_4_1986
import RFC_1123
import Time_Primitives
import Standard_Library_Extensions

// MARK: - Constants

extension [UInt8] {
    package static let fromPrefix: [UInt8] = .init(utf8: "From: ")
    package static let toPrefix: [UInt8] = .init(utf8: "To: ")
    package static let ccPrefix: [UInt8] = .init(utf8: "Cc: ")
    package static let subjectPrefix: [UInt8] = .init(utf8: "Subject: ")
    package static let datePrefix: [UInt8] = .init(utf8: "Date: ")
    package static let messageIdPrefix: [UInt8] = .init(utf8: "Message-ID: ")
    package static let replyToPrefix: [UInt8] = .init(utf8: "Reply-To: ")
    package static let mimeVersionPrefix: [UInt8] = .init(utf8: "MIME-Version: ")
}
