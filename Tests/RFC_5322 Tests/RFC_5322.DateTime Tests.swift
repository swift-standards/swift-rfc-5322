//
//  RFC_5322.DateTime Tests.swift
//  RFC 5322 Tests
//
//  Tests for RFC_5322.DateTime including creation, formatting, and parsing
//

import Testing
import Foundation
@testable import RFC_5322

@Suite
struct `RFC_5322.DateTime Tests` {

    // MARK: - Creation from Epoch

    @Test
    func `Create from seconds since epoch`() throws {
        let dateTime = try RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
        #expect(dateTime.secondsSinceEpoch == 1609459200)
        #expect(dateTime.timezoneOffsetSeconds == 0)
    }

    @Test
    func `Create from epoch with timezone offset`() throws {
        let dateTime = try RFC_5322.DateTime(
            secondsSinceEpoch: 1609459200,
            timezoneOffsetSeconds: 3600  // +01:00
        )
        #expect(dateTime.secondsSinceEpoch == 1609459200)
        #expect(dateTime.timezoneOffsetSeconds == 3600)
    }

    // MARK: - Creation from Components

    @Test
    func `Create from date components`() throws {
        let dateTime = try RFC_5322.DateTime(
            year: 2024,
            month: 1,
            day: 15,
            hour: 12,
            minute: 30,
            second: 45
        )

        let components = dateTime.components
        #expect(components.year == 2024)
        #expect(components.month == 1)
        #expect(components.day == 15)
        #expect(components.hour == 12)
        #expect(components.minute == 30)
        #expect(components.second == 45)
    }

    @Test
    func `Create from components with timezone offset`() throws {
        let dateTime = try RFC_5322.DateTime(
            year: 2024,
            month: 1,
            day: 15,
            hour: 12,
            minute: 30,
            timezoneOffsetSeconds: 3600
        )

        #expect(dateTime.timezoneOffsetSeconds == 3600)
    }

    // MARK: - Components Extraction

    @Test
    func `Extract components from UTC datetime`() throws {
        let dateTime = try RFC_5322.DateTime(
            year: 2021,
            month: 1,
            day: 1,
            hour: 0,
            minute: 0,
            second: 0
        )

        let components = dateTime.components
        #expect(components.year == 2021)
        #expect(components.month == 1)
        #expect(components.day == 1)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test
    func `Components reflect timezone offset`() throws {
        // Create datetime at midnight UTC
        let utcDateTime = try RFC_5322.DateTime(
            year: 2024,
            month: 1,
            day: 1,
            hour: 0,
            minute: 0,
            timezoneOffsetSeconds: 0
        )

        // Same moment but displayed in +03:00 timezone
        let offsetDateTime = try RFC_5322.DateTime(
            secondsSinceEpoch: utcDateTime.secondsSinceEpoch,
            timezoneOffsetSeconds: 10800  // +03:00
        )

        let components = offsetDateTime.components
        // Should show 03:00 local time
        #expect(components.hour == 3)
    }

    // MARK: - Formatting

    @Test
    func `Format datetime as RFC 5322 string`() throws {
        let dateTime = try RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
        let formatted = dateTime.description

        #expect(!formatted.isEmpty)
        #expect(formatted.contains(","))
        #expect(formatted.contains(":"))
    }

    @Test("Format includes day name")
    func formatIncludesDayName() throws {
        let dateTime = try RFC_5322.DateTime(
            year: 2024,
            month: 1,
            day: 1  // Monday
        )
        let formatted = String(dateTime)

        #expect(formatted.hasPrefix("Mon,"))
    }

    @Test("Format includes timezone offset")
    func formatIncludesTimezone() throws {
        let dateTime = try RFC_5322.DateTime(
            year: 2024,
            month: 1,
            day: 1,
            timezoneOffsetSeconds: 3600  // +01:00
        )
        let formatted = String(dateTime)

        #expect(formatted.contains("+0100"))
    }

    @Test("Format negative timezone offset")
    func formatNegativeTimezone() throws {
        let dateTime = try RFC_5322.DateTime(
            year: 2024,
            month: 1,
            day: 1,
            timezoneOffsetSeconds: -18000  // -05:00
        )
        let formatted = String(dateTime)

        #expect(formatted.contains("-0500"))
    }

    @Test("Format zero-pads single digit values")
    func formatZeroPadding() throws {
        let dateTime = try RFC_5322.DateTime(
            year: 2024,
            month: 1,  // Should be "01"
            day: 5,    // Should be "05"
            hour: 9,   // Should be "09"
            minute: 3  // Should be "03"
        )
        let formatted = String(dateTime)

        #expect(formatted.contains("Jan"))  // Month name
        #expect(formatted.contains("05"))  // Day
        #expect(formatted.contains("09:03"))  // Hour:Minute
    }

    // MARK: - Parsing

    @Test("Parse RFC 5322 datetime string")
    func parseDatetimeString() throws {
        let parser = try RFC_5322.DateTime(secondsSinceEpoch: 0)
        let dateTime = try parser.parse("Fri, 01 Jan 2021 12:00:00 +0000")

        let components = dateTime.components
        #expect(components.year == 2021)
        #expect(components.month == 1)
        #expect(components.day == 1)
        #expect(components.hour == 12)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test("Parse datetime with timezone offset")
    func parseDatetimeWithTimezone() throws {
        let parser = try RFC_5322.DateTime(secondsSinceEpoch: 0)
        let dateTime = try parser.parse("Mon, 15 Jan 2024 14:30:00 +0500")

        #expect(dateTime.timezoneOffsetSeconds == 18000)  // 5 hours = 18000 seconds
    }

    @Test("Parse datetime with negative timezone")
    func parseDatetimeWithNegativeTimezone() throws {
        let parser = try RFC_5322.DateTime(secondsSinceEpoch: 0)
        let dateTime = try parser.parse("Mon, 15 Jan 2024 14:30:00 -0800")

        #expect(dateTime.timezoneOffsetSeconds == -28800)  // -8 hours
    }

    @Test("Parse datetime validates weekday")
    func parseDatetimeValidatesWeekday() throws {
        let parser = try RFC_5322.DateTime(secondsSinceEpoch: 0)

        // January 1, 2021 is a Friday
        #expect(throws: RFC_5322.Date.Error.self) {
            _ = try parser.parse("Mon, 01 Jan 2021 12:00:00 +0000")  // Wrong weekday
        }
    }

    // MARK: - Leap Years

    @Test("Handle leap year February 29")
    func handleLeapYearDate() throws {
        let dateTime = try RFC_5322.DateTime(
            year: 2024,  // Leap year
            month: 2,
            day: 29
        )

        let components = dateTime.components
        #expect(components.year == 2024)
        #expect(components.month == 2)
        #expect(components.day == 29)
    }

    @Test("Non-leap year February 28")
    func handleNonLeapYearDate() throws {
        let dateTime = try RFC_5322.DateTime(
            year: 2023,  // Not a leap year
            month: 2,
            day: 28
        )

        let components = dateTime.components
        #expect(components.year == 2023)
        #expect(components.month == 2)
        #expect(components.day == 28)
    }

    // MARK: - Comparison

    @Test("Compare datetimes")
    func compareDatetimes() throws {
        let earlier = try RFC_5322.DateTime(secondsSinceEpoch: 1000)
        let later = try RFC_5322.DateTime(secondsSinceEpoch: 2000)

        #expect(earlier < later)
        #expect(later > earlier)
    }

    @Test("Equal datetimes")
    func equalDatetimes() throws {
        let dateTime1 = try RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
        let dateTime2 = try RFC_5322.DateTime(secondsSinceEpoch: 1609459200)

        #expect(dateTime1 == dateTime2)
    }

    @Test
    func `Comparison ignores timezone offset`() throws {
        let utc = try RFC_5322.DateTime(
            secondsSinceEpoch: 1609459200,
            timezoneOffsetSeconds: 0
        )
        let offset = try RFC_5322.DateTime(
            secondsSinceEpoch: 1609459200,
            timezoneOffsetSeconds: 3600
        )

        // Same epoch time = same moment in time
        #expect(utc == offset)
    }

    // MARK: - Codable

    @Test
    func `Encode and decode datetime`() throws {
        let original = try RFC_5322.DateTime(
            secondsSinceEpoch: 1609459200,
            timezoneOffsetSeconds: 3600
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RFC_5322.DateTime.self, from: data)

        #expect(decoded.secondsSinceEpoch == original.secondsSinceEpoch)
        #expect(decoded.timezoneOffsetSeconds == original.timezoneOffsetSeconds)
    }

    @Test
    func `Decode datetime without timezone defaults to UTC`() throws {
        // Simulate old data that only has secondsSinceEpoch
        let json = "{\"secondsSinceEpoch\":1609459200}"
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        let dateTime = try decoder.decode(RFC_5322.DateTime.self, from: data)

        #expect(dateTime.timezoneOffsetSeconds == 0)
    }

    // MARK: - Arithmetic

    @Test
    func `Add time interval`() throws {
        let dateTime = try RFC_5322.DateTime(secondsSinceEpoch: 1000)
        let later = dateTime.adding(500)

        #expect(later.secondsSinceEpoch == 1500)
    }

    @Test
    func `Subtract time interval`() throws {
        let dateTime = try RFC_5322.DateTime(secondsSinceEpoch: 1000)
        let earlier = dateTime.subtracting(500)

        #expect(earlier.secondsSinceEpoch == 500)
    }

    // MARK: - Edge Cases

    @Test
    func `Handle Unix epoch`() throws {
        let epoch = try RFC_5322.DateTime(secondsSinceEpoch: 0)
        let components = epoch.components

        #expect(components.year == 1970)
        #expect(components.month == 1)
        #expect(components.day == 1)
    }

    @Test
    func `Handle year 2000`() throws {
        let y2k = try RFC_5322.DateTime(
            year: 2000,
            month: 1,
            day: 1
        )

        let components = y2k.components
        #expect(components.year == 2000)
    }

    @Test
    func `Handle far future date`() throws {
        let future = try RFC_5322.DateTime(
            year: 2100,
            month: 12,
            day: 31
        )

        let components = future.components
        #expect(components.year == 2100)
        #expect(components.month == 12)
        #expect(components.day == 31)
    }

    // MARK: - Validation Tests

    @Test
    func `Reject invalid month`() {
        #expect(throws: RFC_5322.Date.Error.self) {
            _ = try RFC_5322.DateTime(year: 2024, month: 13, day: 1)
        }
        #expect(throws: RFC_5322.Date.Error.self) {
            _ = try RFC_5322.DateTime(year: 2024, month: 0, day: 1)
        }
    }

    @Test
    func `Reject invalid day for month`() {
        // February 30 doesn't exist
        #expect(throws: RFC_5322.Date.Error.self) {
            _ = try RFC_5322.DateTime(year: 2024, month: 2, day: 30)
        }
        // April has only 30 days
        #expect(throws: RFC_5322.Date.Error.self) {
            _ = try RFC_5322.DateTime(year: 2024, month: 4, day: 31)
        }
        // Day 0 is invalid
        #expect(throws: RFC_5322.Date.Error.self) {
            _ = try RFC_5322.DateTime(year: 2024, month: 1, day: 0)
        }
    }

    @Test
    func `Reject invalid day for leap year`() {
        // 2024 is a leap year, Feb 29 is valid
        #expect(throws: Never.self) {
            _ = try RFC_5322.DateTime(year: 2024, month: 2, day: 29)
        }
        // 2023 is not a leap year, Feb 29 is invalid
        #expect(throws: RFC_5322.Date.Error.self) {
            _ = try RFC_5322.DateTime(year: 2023, month: 2, day: 29)
        }
    }

    @Test
    func `Reject invalid hour`() {
        #expect(throws: RFC_5322.Date.Error.self) {
            _ = try RFC_5322.DateTime(year: 2024, month: 1, day: 1, hour: 24)
        }
        #expect(throws: RFC_5322.Date.Error.self) {
            _ = try RFC_5322.DateTime(year: 2024, month: 1, day: 1, hour: -1)
        }
    }

    @Test
    func `Reject invalid minute`() {
        #expect(throws: RFC_5322.Date.Error.self) {
            _ = try RFC_5322.DateTime(year: 2024, month: 1, day: 1, minute: 60)
        }
        #expect(throws: RFC_5322.Date.Error.self) {
            _ = try RFC_5322.DateTime(year: 2024, month: 1, day: 1, minute: -1)
        }
    }

    @Test
    func `Reject invalid second`() {
        // Second 60 is valid (leap second)
        #expect(throws: Never.self) {
            _ = try RFC_5322.DateTime(year: 2024, month: 1, day: 1, second: 60)
        }
        // Second 61 is invalid
        #expect(throws: RFC_5322.Date.Error.self) {
            _ = try RFC_5322.DateTime(year: 2024, month: 1, day: 1, second: 61)
        }
        #expect(throws: RFC_5322.Date.Error.self) {
            _ = try RFC_5322.DateTime(year: 2024, month: 1, day: 1, second: -1)
        }
    }

    // MARK: - Year 2100 Edge Case Tests (century year, not a leap year)

    @Test
    func `Year 2100 is not a leap year`() {
        // 2100 is divisible by 100 but not 400, so NOT a leap year
        let feb28 = try? RFC_5322.DateTime(year: 2100, month: 2, day: 28)
        #expect(feb28 != nil)

        let feb29 = try? RFC_5322.DateTime(year: 2100, month: 2, day: 29)
        #expect(feb29 == nil) // Should fail - 2100 is not a leap year
    }

    @Test
    func `Round-trip 2100-01-01`() throws {
        let dt = try RFC_5322.DateTime(year: 2100, month: 1, day: 1)
        let components = dt.components
        #expect(components.year == 2100)
        #expect(components.month == 1)
        #expect(components.day == 1)
    }

    @Test
    func `Round-trip 2100-12-30`() throws {
        let dt = try RFC_5322.DateTime(year: 2100, month: 12, day: 30)
        let components = dt.components
        #expect(components.year == 2100)
        #expect(components.month == 12)
        #expect(components.day == 30)
    }

    @Test
    func `Days since epoch for 2100-12-31`() throws {
        let dt1 = try RFC_5322.DateTime(year: 2100, month: 12, day: 31)
        let dt2 = try RFC_5322.DateTime(year: 2101, month: 1, day: 1)

        // Should be exactly 1 day apart
        #expect(dt2.secondsSinceEpoch - dt1.secondsSinceEpoch == 86400)
    }
}
