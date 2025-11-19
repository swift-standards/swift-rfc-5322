//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 18/11/2025.
//

extension RFC_5322.Date {
    /// Errors that can occur when parsing RFC 5322 date-time strings or creating date components
    public enum Error: Swift.Error, Sendable, Equatable {
        case invalidFormat(String)
        case invalidDayName(String)
        case invalidDay(String)
        case invalidMonth(String)
        case invalidYear(String)
        case invalidTime(String)
        case invalidHour(String)
        case invalidMinute(String)
        case invalidSecond(String)
        case invalidTimezone(String)
        case weekdayMismatch(expected: String, actual: String)

        // Component validation errors
        case monthOutOfRange(Int)           // Must be 1-12
        case dayOutOfRange(Int, month: Int, year: Int)  // Must be valid for month/year
        case hourOutOfRange(Int)            // Must be 0-23
        case minuteOutOfRange(Int)          // Must be 0-59
        case secondOutOfRange(Int)          // Must be 0-60 (allowing leap second)
        case weekdayOutOfRange(Int)         // Must be 0-6
    }
}
