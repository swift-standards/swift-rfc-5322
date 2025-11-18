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

        public init(
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
}
