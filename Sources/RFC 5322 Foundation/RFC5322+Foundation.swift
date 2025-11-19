//
//  Foundation+RFC5322.swift
//  swift-rfc-5322
//
//  Foundation.Date formatting extensions for RFC 5322
//

#if canImport(Foundation)
import Foundation
import RFC_5322

// MARK: - RFC 5322 Format Style for Foundation.Date

extension RFC_5322.Date {
    /// Format style for converting Foundation.Date to RFC 5322 date-time strings
    ///
    /// Enables the syntax: `Date().formatted(.rfc5322)`
    public struct FormatStyle: Sendable {
        /// Timezone offset in seconds from UTC (default: 0 for UTC)
        public let timezoneOffsetSeconds: Int

        /// Create a format style with specific timezone offset
        /// - Parameter timezoneOffsetSeconds: Timezone offset in seconds (default: 0 for UTC)
        public init(timezoneOffsetSeconds: Int = 0) {
            self.timezoneOffsetSeconds = timezoneOffsetSeconds
        }

        /// Format a Foundation.Date as RFC 5322 date-time string
        public func format(_ date: Foundation.Date) -> String {
            let dateTime = RFC_5322.DateTime(
                secondsSinceEpoch: Int(date.timeIntervalSince1970),
                timezoneOffsetSeconds: timezoneOffsetSeconds
            )
            return dateTime.format(dateTime)
        }

        /// Parse an RFC 5322 date-time string into a Foundation.Date
        public func parse(_ value: String) throws -> Foundation.Date {
            let dateTime = try RFC_5322.DateTime.Parser.parse(value)
            return Foundation.Date(timeIntervalSince1970: TimeInterval(dateTime.secondsSinceEpoch))
        }
    }
}

// MARK: - Foundation.Date Extensions

extension Foundation.Date {
    /// Format this date as an RFC 5322 date-time string
    ///
    /// - Parameter style: The RFC 5322 format style to use
    /// - Returns: RFC 5322 formatted date-time string
    ///
    /// ## Example
    ///
    /// ```swift
    /// let date = Date()
    /// let formatted = date.formatted(.rfc5322)
    /// // "Mon, 01 Jan 2024 12:34:56 +0000"
    ///
    /// // With timezone offset
    /// let est = date.formatted(.rfc5322(timezoneOffsetSeconds: -18000))
    /// // "Mon, 01 Jan 2024 07:34:56 -0500"
    /// ```
    public func formatted(_ style: RFC_5322.Date.FormatStyle) -> String {
        style.format(self)
    }

    /// Parse an RFC 5322 date-time string into a Foundation.Date
    ///
    /// - Parameters:
    ///   - value: The RFC 5322 date-time string
    ///   - strategy: The format style to use (default: UTC)
    /// - Returns: Foundation.Date
    /// - Throws: RFC_5322.Date.Error if parsing fails
    ///
    /// ## Example
    ///
    /// ```swift
    /// let date = try Date("Mon, 01 Jan 2024 12:34:56 +0000", strategy: .rfc5322)
    /// ```
    public init(_ value: String, strategy: RFC_5322.Date.FormatStyle) throws {
        let foundationDate = try strategy.parse(value)
        self = foundationDate
    }
}

// MARK: - Static Accessors

extension RFC_5322.Date.FormatStyle {
    /// RFC 5322 format style with UTC timezone (+0000)
    public static var rfc5322: RFC_5322.Date.FormatStyle {
        RFC_5322.Date.FormatStyle(timezoneOffsetSeconds: 0)
    }

    /// RFC 5322 format style with custom timezone offset
    ///
    /// - Parameter timezoneOffsetSeconds: Timezone offset in seconds from UTC
    /// - Returns: RFC 5322 format style
    ///
    /// ## Example
    ///
    /// ```swift
    /// // EST (UTC-5)
    /// Date().formatted(.rfc5322(timezoneOffsetSeconds: -18000))
    ///
    /// // CET (UTC+1)
    /// Date().formatted(.rfc5322(timezoneOffsetSeconds: 3600))
    /// ```
    public static func rfc5322(timezoneOffsetSeconds: Int) -> Self {
        Self(timezoneOffsetSeconds: timezoneOffsetSeconds)
    }
}

// MARK: - RFC_5322.DateTime <-> Foundation.Date Conversion

extension RFC_5322.DateTime {
    /// Convert this RFC 5322 DateTime to a Foundation.Date
    ///
    /// The Foundation.Date represents the same instant in time (UTC),
    /// but timezone offset information is not preserved.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let dt = RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
    /// let foundationDate = dt.foundationDate
    /// ```
    public var foundationDate: Foundation.Date {
        Foundation.Date(timeIntervalSince1970: TimeInterval(secondsSinceEpoch))
    }

    /// Create an RFC 5322 DateTime from a Foundation.Date
    ///
    /// - Parameters:
    ///   - date: The Foundation.Date to convert
    ///   - timezoneOffsetSeconds: Timezone offset in seconds (default: 0 for UTC)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let date = Date()
    /// let dt = RFC_5322.DateTime(foundationDate: date)
    /// let dtEST = RFC_5322.DateTime(foundationDate: date, timezoneOffsetSeconds: -18000)
    /// ```
    public init(foundationDate date: Foundation.Date, timezoneOffsetSeconds: Int = 0) {
        self.init(
            secondsSinceEpoch: Int(date.timeIntervalSince1970),
            timezoneOffsetSeconds: timezoneOffsetSeconds
        )
    }
}

// MARK: - Foundation.Date FormatStyle Support

extension RFC_5322.DateTime {
    /// Format this DateTime using any Foundation.Date.FormatStyle
    ///
    /// This enables using ALL of Foundation's date formatting capabilities
    /// on RFC 5322 DateTimes.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let dt = RFC_5322.DateTime(year: 2024, month: 1, day: 1)
    ///
    /// // ISO 8601
    /// dt.formatted(Date.ISO8601FormatStyle())
    ///
    /// // Custom Foundation format
    /// dt.formatted(Date.FormatStyle()
    ///     .year().month().day()
    ///     .hour().minute().second()
    /// )
    ///
    /// // Relative formatting
    /// dt.formatted(.relative(presentation: .named))
    /// ```
    ///
    /// - Parameter style: Any Foundation.Date.FormatStyle
    /// - Returns: Formatted string
    public func formatted<F: Foundation.FormatStyle>(_ style: F) -> F.FormatOutput
        where F.FormatInput == Foundation.Date
    {
        foundationDate.formatted(style)
    }
}

#if swift(>=5.9)
// MARK: - Foundation.Date Convenience Formatting

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension RFC_5322.DateTime {
    /// Format this DateTime using Foundation's convenient date/time format syntax
    ///
    /// ## Example
    ///
    /// ```swift
    /// let dt = RFC_5322.DateTime(year: 2024, month: 1, day: 1, hour: 12, minute: 30)
    ///
    /// // Just date
    /// dt.formatted(date: .long, time: .omitted)
    /// // "January 1, 2024"
    ///
    /// // Date and time
    /// dt.formatted(date: .numeric, time: .standard)
    /// // "1/1/2024, 12:30:00 PM"
    ///
    /// // Custom
    /// dt.formatted(date: .abbreviated, time: .shortened)
    /// // "Jan 1, 2024, 12:30 PM"
    /// ```
    public func formatted(
        date: Foundation.Date.FormatStyle.DateStyle,
        time: Foundation.Date.FormatStyle.TimeStyle
    ) -> String {
        foundationDate.formatted(date: date, time: time)
    }
}
#endif

#endif

