//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 18/11/2025.
//

extension RFC_5322.DateTime {
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

        case components(RFC_5322.Date.Components.Error)
    }
}
