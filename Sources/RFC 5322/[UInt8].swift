//
//  [UInt8].swift
//  swift-rfc-5322
//
//  Type conversions for RFC 5322 Message
//

import Standards
import StandardTime
import INCITS_4_1986
import RFC_1123

// MARK: - Constants

package extension [UInt8] {
    static let fromPrefix: [UInt8] = .init(utf8: "From: ")
    static let toPrefix: [UInt8] = .init(utf8: "To: ")
    static let ccPrefix: [UInt8] = .init(utf8: "Cc: ")
    static let subjectPrefix: [UInt8] = .init(utf8: "Subject: ")
    static let datePrefix: [UInt8] = .init(utf8: "Date: ")
    static let messageIdPrefix: [UInt8] = .init(utf8: "Message-ID: ")
    static let replyToPrefix: [UInt8] = .init(utf8: "Reply-To: ")
    static let mimeVersionPrefix: [UInt8] = .init(utf8: "MIME-Version: ")
}
