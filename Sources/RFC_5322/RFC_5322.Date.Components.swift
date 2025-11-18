//
//  File.swift
//  swift-rfc-5322
//
//  Created by Coen ten Thije Boonkkamp on 18/11/2025.
//

extension RFC_5322.Date {

    /// Date components extracted from a date-time
    public struct Components: Sendable, Equatable {
        public let year: Int
        public let month: Int      // 1-12
        public let day: Int        // 1-31
        public let hour: Int       // 0-23
        public let minute: Int     // 0-59
        public let second: Int     // 0-60 (allowing leap second)
        public let weekday: Int    // 0=Sunday, 6=Saturday

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
        ) throws {
            // Validate month
            guard (1...12).contains(month) else {
                throw RFC_5322.Date.Error.monthOutOfRange(month)
            }

            // Validate day for the given month and year
            let maxDay = Self.daysInMonth(month, year: year)
            guard (1...maxDay).contains(day) else {
                throw RFC_5322.Date.Error.dayOutOfRange(day, month: month, year: year)
            }

            // Validate hour
            guard (0...23).contains(hour) else {
                throw RFC_5322.Date.Error.hourOutOfRange(hour)
            }

            // Validate minute
            guard (0...59).contains(minute) else {
                throw RFC_5322.Date.Error.minuteOutOfRange(minute)
            }

            // Validate second (allowing 60 for leap second)
            guard (0...60).contains(second) else {
                throw RFC_5322.Date.Error.secondOutOfRange(second)
            }

            // Validate weekday
            guard (0...6).contains(weekday) else {
                throw RFC_5322.Date.Error.weekdayOutOfRange(weekday)
            }

            self.year = year
            self.month = month
            self.day = day
            self.hour = hour
            self.minute = minute
            self.second = second
            self.weekday = weekday
        }

        /// Returns the number of days in the given month for the given year
        private static func daysInMonth(_ month: Int, year: Int) -> Int {
            switch month {
            case 1, 3, 5, 7, 8, 10, 12:
                return 31
            case 4, 6, 9, 11:
                return 30
            case 2:
                return isLeapYear(year) ? 29 : 28
            default:
                return 0
            }
        }

        /// Returns true if the year is a leap year
        private static func isLeapYear(_ year: Int) -> Bool {
            (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
        }
    }
}
