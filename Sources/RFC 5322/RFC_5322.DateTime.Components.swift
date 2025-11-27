//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 18/11/2025.
//

import StandardTime

extension RFC_5322.Date {

    /// Date components extracted from a date-time
    public struct Components: Sendable, Equatable {
        public let year: Int
        public let month: Int  // 1-12
        public let day: Int  // 1-31
        public let hour: Int  // 0-23
        public let minute: Int  // 0-59
        public let second: Int  // 0-60 (allowing leap second)
        public let weekday: Int  // 0=Sunday, 6=Saturday

        /// Creates date components with validation
        /// - Throws: `RFC_5322.Date.Error` if any component is out of valid range
        public init(
            year: Int,
            month: Int,
            day: Int,
            hour: Int,
            minute: Int,
            second: Int,
            weekday: Int
        ) throws(Error) {
            // Validate month
            guard (1...12).contains(month) else {
                throw Error.monthOutOfRange(month)
            }

            // Validate day for the given month and year
            // Use Time module's calendar calculations (month already validated as 1-12)
            let maxDay = Time.Calendar.Gregorian.daysInMonths(year: year)[month - 1]
            guard (1...maxDay).contains(day) else {
                throw Error.dayOutOfRange(day, month: month, year: year)
            }

            // Validate hour
            guard (0...23).contains(hour) else {
                throw Error.hourOutOfRange(hour)
            }

            // Validate minute
            guard (0...59).contains(minute) else {
                throw Error.minuteOutOfRange(minute)
            }

            // Validate second (allowing 60 for leap second)
            guard (0...60).contains(second) else {
                throw Error.secondOutOfRange(second)
            }

            // Validate weekday
            guard (0...6).contains(weekday) else {
                throw Error.weekdayOutOfRange(weekday)
            }

            self.year = year
            self.month = month
            self.day = day
            self.hour = hour
            self.minute = minute
            self.second = second
            self.weekday = weekday
        }
    }
}

extension RFC_5322.DateTime.Components {
    /// Creates date components without validation (internal use only)
    ///
    /// This initializer bypasses validation and should only be used when component values
    /// are known to be valid (e.g., computed from epoch seconds).
    ///
    /// - Warning: Using this with invalid values will create an invalid Components instance.
    ///   Only use when values are guaranteed valid by construction.
    init(
        __unchecked: Void,
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        weekday: Int
    ) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.weekday = weekday
    }
}
