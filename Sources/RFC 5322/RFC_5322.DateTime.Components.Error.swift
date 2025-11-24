//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 24/11/2025.
//

// MARK: - Errors
extension RFC_5322.DateTime.Components {
    public enum Error: Swift.Error, Sendable, Equatable {
        case monthOutOfRange(Int)           // Must be 1-12
        case dayOutOfRange(Int, month: Int, year: Int)  // Must be valid for month/year
        case hourOutOfRange(Int)            // Must be 0-23
        case minuteOutOfRange(Int)          // Must be 0-59
        case secondOutOfRange(Int)          // Must be 0-60 (allowing leap second)
        case weekdayOutOfRange(Int)         // Must be 0-6
    }
}
