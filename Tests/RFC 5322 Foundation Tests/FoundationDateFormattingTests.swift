//
//  FoundationDateFormattingTests.swift
//  swift-rfc-5322
//
//  Tests for formatting Foundation.Date as RFC 5322
//

import Foundation
import RFC_5322
import RFC_5322_Foundation
import Testing

@Suite
struct `Foundation Date Formatting` {

    @Test
    func `Format Foundation.Date as RFC 5322`() throws {
        // January 1, 2021 00:00:00 UTC
        let date = Date(timeIntervalSince1970: 1609459200)

        let formatted = date.formatted(.rfc5322)

        // Should be a valid RFC 5322 date-time string
        #expect(formatted.contains("Fri"))  // Day name
        #expect(formatted.contains("01"))   // Day
        #expect(formatted.contains("Jan"))  // Month
        #expect(formatted.contains("2021")) // Year
        #expect(formatted.contains("+0000")) // UTC timezone
    }

    @Test
    func `Format Foundation.Date with custom timezone`() throws {
        // January 1, 2021 00:00:00 UTC
        let date = Date(timeIntervalSince1970: 1609459200)

        // Format with EST timezone (-0500)
        let formatted = date.formatted(.rfc5322(timezoneOffsetSeconds: -18000))

        #expect(formatted.contains("Thu"))  // One day earlier
        #expect(formatted.contains("31"))   // 31st
        #expect(formatted.contains("Dec"))  // December
        #expect(formatted.contains("2020")) // 2020
        #expect(formatted.contains("-0500")) // EST timezone
    }

    @Test
    func `Parse RFC 5322 string to Foundation.Date`() throws {
        let parsed = try Date("Fri, 01 Jan 2021 00:00:00 +0000", strategy: .rfc5322)

        #expect(parsed.timeIntervalSince1970 == 1609459200)
    }
}

@Suite
struct `RFC 5322 DateTime with Foundation Formatting` {

    @Test
    func `Convert RFC 5322 DateTime to Foundation.Date`() throws {
        let dt = RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
        let foundationDate = dt.foundationDate

        #expect(foundationDate.timeIntervalSince1970 == 1609459200)
    }

    @Test
    func `Convert Foundation.Date to RFC 5322 DateTime`() throws {
        let date = Date(timeIntervalSince1970: 1609459200)
        let dt = RFC_5322.DateTime(foundationDate: date)

        #expect(dt.secondsSinceEpoch == 1609459200)
        #expect(dt.timezoneOffsetSeconds == 0)
    }

    @Test
    func `Convert with custom timezone`() throws {
        let date = Date(timeIntervalSince1970: 1609459200)
        let dt = RFC_5322.DateTime(foundationDate: date, timezoneOffsetSeconds: -18000)

        #expect(dt.secondsSinceEpoch == 1609459200)
        #expect(dt.timezoneOffsetSeconds == -18000)
    }

    @Test
    func `Format RFC 5322 DateTime using ISO 8601`() throws {
        let dt = RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
        let formatted = dt.formatted(Date.ISO8601FormatStyle())

        // ISO 8601 format
        #expect(formatted.contains("2021"))
        #expect(formatted.contains("01"))
        #expect(formatted.contains("T") || formatted.contains("-"))
    }

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    @Test
    func `Format RFC 5322 DateTime with date and time styles`() throws {
        let dt = try RFC_5322.DateTime(year: 2024, month: 1, day: 15, hour: 14, minute: 30)

        // Numeric date, standard time
        let formatted = dt.formatted(date: .numeric, time: .standard)

        #expect(formatted.contains("2024") || formatted.contains("24"))
        #expect(formatted.contains("1") || formatted.contains("01"))
        #expect(formatted.contains("15"))
    }

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    @Test
    func `Format RFC 5322 DateTime with long date style`() throws {
        let dt = try RFC_5322.DateTime(year: 2024, month: 6, day: 15)

        let formatted = dt.formatted(date: .long, time: .omitted)

        // Should contain month name and year
        #expect(formatted.contains("2024"))
        #expect(formatted.contains("15"))
    }

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    @Test
    func `Format RFC 5322 DateTime with custom FormatStyle`() throws {
        let dt = try RFC_5322.DateTime(year: 2024, month: 3, day: 21, hour: 15, minute: 45)

        let formatted = dt.formatted(
            Date.FormatStyle()
                .year()
                .month(.abbreviated)
                .day()
                .hour()
                .minute()
        )

        // Check major components (hour may vary based on system timezone)
        #expect(formatted.contains("2024"))
        #expect(formatted.contains("21"))
        #expect(formatted.contains("45"))
        // Verify some hour is present (formatted in local timezone)
        #expect(formatted.range(of: #"\d{1,2}:\d{2}|at \d{1,2}:\d{2}"#, options: .regularExpression) != nil)
    }
}
