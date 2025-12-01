// DateTime.swift
// RFC 5322
//
// RFC 5322 date-time representation and formatting
// Format: "Mon, 01 Jan 2024 12:34:56 +0000"

import INCITS_4_1986
public import StandardTime
import Standards

extension RFC_5322 {
    /// RFC 5322 date-time representation
    ///
    /// Represents a date-time value per RFC 5322 section 3.3.
    /// The RFC calls this a "date-time" (not "timestamp" or "date").
    /// Uses Standards/Time as the foundation for all calendar logic.
    ///
    /// Example:
    /// ```swift
    /// let dateTime = try RFC_5322.DateTime(year: 2024, month: 1, day: 1, hour: 12, minute: 30)
    /// print(dateTime.format(dateTime))  // "Mon, 01 Jan 2024 12:30:00 +0000"
    /// ```
    public struct DateTime: Sendable, Equatable, Hashable, Comparable {
        /// The UTC time
        public let time: Time

        /// Timezone offset from UTC
        /// Positive values are east of UTC, negative values are west
        /// Example: +0100 = 1 hour, -0500 = -5 hours
        public let timezoneOffset: Time.TimezoneOffset

        /// Create a date-time from Time and timezone offset
        /// - Parameters:
        ///   - time: The UTC time
        ///   - timezoneOffset: Timezone offset (default: UTC)
        public init(time: Time, timezoneOffset: Time.TimezoneOffset = .utc) {
            self.time = time
            self.timezoneOffset = timezoneOffset
        }
    }
}

extension RFC_5322 {
    public typealias Date = RFC_5322.DateTime
}

extension RFC_5322.DateTime: UInt8.ASCII.Serializable {
    static public func serialize<Buffer>(ascii dateTime: RFC_5322.DateTime, into buffer: inout Buffer) where Buffer : RangeReplaceableCollection, Buffer.Element == UInt8 {
        let components = dateTime.components

        buffer.reserveCapacity(31)  // "Mon, 01 Jan 2024 12:34:56 +0000" = 31 bytes

        // Day name (e.g., "Mon")
        let dayName = RFC_5322.DateTime.dayNames[components.weekday]
        buffer.append(utf8: dayName)
        buffer.append(.ascii.comma)
        buffer.append(.ascii.space)

        // Day (zero-padded 2 digits)
        let day = components.day.zeroPaddedTwoDigits()
        buffer.append(utf8: day)
        buffer.append(.ascii.space)

        // Month name (e.g., "Jan")
        let monthName = RFC_5322.DateTime.monthNames[components.month - 1]
        buffer.append(utf8: monthName)
        buffer.append(.ascii.space)

        // Year (4 digits)
        let year = components.year.zeroPaddedFourDigits()
        buffer.append(utf8: year)
        buffer.append(.ascii.space)

        // Hour (zero-padded 2 digits)
        let hour = components.hour.zeroPaddedTwoDigits()
        buffer.append(utf8: hour)
        buffer.append(.ascii.colon)

        // Minute (zero-padded 2 digits)
        let minute = components.minute.zeroPaddedTwoDigits()
        buffer.append(utf8: minute)
        buffer.append(.ascii.colon)

        // Second (zero-padded 2 digits)
        let second = components.second.zeroPaddedTwoDigits()
        buffer.append(utf8: second)
        buffer.append(.ascii.space)

        // Timezone offset
        let offsetSign = dateTime.timezoneOffsetSeconds >= 0 ? "+" : "-"
        buffer.append(utf8: offsetSign)

        let offsetHours =
            abs(dateTime.timezoneOffsetSeconds)
            / Time.Calendar.Gregorian.TimeConstants.secondsPerHour
        let offsetMinutes =
            (abs(dateTime.timezoneOffsetSeconds)
                % Time.Calendar.Gregorian.TimeConstants.secondsPerHour)
            / Time.Calendar.Gregorian.TimeConstants.secondsPerMinute

        let offsetHoursStr = offsetHours.zeroPaddedTwoDigits()
        buffer.append(utf8: offsetHoursStr)

        let offsetMinutesStr = offsetMinutes.zeroPaddedTwoDigits()
        buffer.append(utf8: offsetMinutesStr)
    }

    /// Parses RFC 5322 date-time from canonical byte representation (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 5322 date-times are ASCII-only.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_5322.DateTime (structured data)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [UInt8] (UTF-8 bytes) → DateTime
    /// ```
    ///
    /// ## Format
    ///
    /// Parses RFC 5322 date-time format: "Mon, 01 Jan 2024 12:34:56 +0000"
    /// Supports optional seconds: "Mon, 01 Jan 2024 12:34 +0000"
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array("Mon, 01 Jan 2024 12:00:00 +0000".utf8)
    /// let dateTime = try RFC_5322.DateTime(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the date-time
    /// - Throws: `RFC_5322.DateTime.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        // Split on spaces at byte level
        var parts: [[UInt8]] = []
        var currentPart: [UInt8] = []

        for byte in bytes {
            if byte == .ascii.space {
                if !currentPart.isEmpty {
                    parts.append(currentPart)
                    currentPart = []
                }
            } else {
                currentPart.append(byte)
            }
        }
        if !currentPart.isEmpty {
            parts.append(currentPart)
        }

        // Expect at least 6 parts: "Mon," "01" "Jan" "2024" "12:34:56" "+0000"
        guard parts.count >= 6 else {
            throw Error.invalidFormat("Expected at least 6 components, got \(parts.count)")
        }

        // Parse day name (remove trailing comma if present)
        let dayNameBytes = parts[0].last == .ascii.comma ? parts[0].dropLast() : parts[0][...]
        let dayName = String(decoding: dayNameBytes, as: UTF8.self)

        guard let expectedWeekday = RFC_5322.DateTime.dayNames.firstIndex(of: dayName) else {
            throw Error.invalidDayName(dayName)
        }

        // Parse day (2 digits)
        let dayString = String(decoding: parts[1], as: UTF8.self)
        guard let day = Int(dayString), day >= 1, day <= 31 else {
            throw Error.invalidDay(dayString)
        }

        // Parse month (3-letter abbreviation)
        let monthString = String(decoding: parts[2], as: UTF8.self)
        guard let monthIndex = RFC_5322.DateTime.monthNames.firstIndex(of: monthString) else {
            throw Error.invalidMonth(monthString)
        }
        let month = monthIndex + 1

        // Parse year (4 digits)
        let yearString = String(decoding: parts[3], as: UTF8.self)
        guard let year = Int(yearString), year >= 1900 else {
            throw Error.invalidYear(yearString)
        }

        // Parse time (HH:MM:SS or HH:MM) at byte level
        let timeBytes = parts[4]
        var timeParts: [[UInt8]] = []
        var currentTimePart: [UInt8] = []

        for byte in timeBytes {
            if byte == .ascii.colon {
                if !currentTimePart.isEmpty {
                    timeParts.append(currentTimePart)
                    currentTimePart = []
                }
            } else {
                currentTimePart.append(byte)
            }
        }
        if !currentTimePart.isEmpty {
            timeParts.append(currentTimePart)
        }

        guard timeParts.count >= 2, timeParts.count <= 3 else {
            let timeString = String(decoding: timeBytes, as: UTF8.self)
            throw Error.invalidTime(timeString)
        }

        let hourString = String(decoding: timeParts[0], as: UTF8.self)
        guard let hour = Int(hourString), hour >= 0, hour <= 23 else {
            throw Error.invalidHour(hourString)
        }

        let minuteString = String(decoding: timeParts[1], as: UTF8.self)
        guard let minute = Int(minuteString), minute >= 0, minute <= 59 else {
            throw Error.invalidMinute(minuteString)
        }

        let second: Int
        if timeParts.count == 3 {
            let secondString = String(decoding: timeParts[2], as: UTF8.self)
            guard let sec = Int(secondString), sec >= 0, sec <= 60 else {  // Allow leap second
                throw Error.invalidSecond(secondString)
            }
            second = sec
        } else {
            second = 0
        }

        // Parse timezone offset at byte level (+0000 or -0500)
        let timezoneBytes = parts[5]
        guard timezoneBytes.count == 5 else {
            let timezoneString = String(decoding: timezoneBytes, as: UTF8.self)
            throw Error.invalidTimezone(timezoneString)
        }

        let sign = timezoneBytes[0] == UInt8.ascii.plus ? 1 : -1
        let offsetBytes = timezoneBytes.dropFirst()

        // Parse hours and minutes from bytes
        let offsetHoursBytes = offsetBytes.prefix(2)
        let offsetMinutesBytes = offsetBytes.suffix(2)

        let offsetHoursString = String(decoding: offsetHoursBytes, as: UTF8.self)
        let offsetMinutesString = String(decoding: offsetMinutesBytes, as: UTF8.self)

        guard let offsetHours = Int(offsetHoursString),
            let offsetMinutes = Int(offsetMinutesString),
            offsetHours >= 0, offsetHours <= 23,
            offsetMinutes >= 0, offsetMinutes <= 59
        else {
            let timezoneString = String(decoding: timezoneBytes, as: UTF8.self)
            throw Error.invalidTimezone(timezoneString)
        }

        let timezoneOffsetSeconds =
            sign
            * (offsetHours * Time.Calendar.Gregorian.TimeConstants.secondsPerHour + offsetMinutes
                * Time.Calendar.Gregorian.TimeConstants.secondsPerMinute)

        // Create date-time in UTC with validated components
        // Time.init throws Time.Error, not our typed error, so we use do-catch
        let dateTime: RFC_5322.DateTime
        do {
            dateTime = try RFC_5322.DateTime(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second
            )
        } catch {
            throw Error.invalidFormat("Date components invalid: \(error)")
        }

        // Adjust for timezone offset to get UTC
        // If timezone is +0500, we subtract 5 hours to get UTC
        let utcDateTime = dateTime.subtracting(timezoneOffsetSeconds)

        // Validate weekday matches (using the local time components)
        let localDateTime = RFC_5322.DateTime(
            secondsSinceEpoch: utcDateTime.secondsSinceEpoch,
            timezoneOffsetSeconds: timezoneOffsetSeconds
        )
        let actualWeekday = localDateTime.components.weekday
        guard actualWeekday == expectedWeekday else {
            throw Error.weekdayMismatch(
                expected: RFC_5322.DateTime.dayNames[expectedWeekday],
                actual: RFC_5322.DateTime.dayNames[actualWeekday]
            )
        }

        self = localDateTime
    }
}

extension RFC_5322.DateTime: CustomStringConvertible {}

extension RFC_5322.DateTime {
    /// Create a date-time from seconds since epoch
    /// - Parameters:
    ///   - secondsSinceEpoch: Seconds since Unix epoch (UTC)
    ///   - timezoneOffsetSeconds: Timezone offset in seconds (default: 0 for UTC)
    public init(secondsSinceEpoch: Int, timezoneOffsetSeconds: Int = 0) {
        self.time = Time(secondsSinceEpoch: secondsSinceEpoch)
        self.timezoneOffset = Time.TimezoneOffset(seconds: timezoneOffsetSeconds)
    }
}

extension RFC_5322.DateTime {
    /// Create a date-time from components with validation
    /// - Parameters:
    ///   - year: Year
    ///   - month: Month (1-12)
    ///   - day: Day (1-31, validated for month/year)
    ///   - hour: Hour (0-23)
    ///   - minute: Minute (0-59)
    ///   - second: Second (0-60, allowing leap second)
    ///   - timezoneOffsetSeconds: Timezone offset in seconds (default: 0 for UTC)
    /// - Throws: `RFC_5322.Date.Error` if any component is out of valid range
    ///
    /// Components are interpreted in UTC, then the timezone offset is applied for display.
    public init(
        year: Int,
        month: Int,  // 1-12
        day: Int,  // 1-31
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        timezoneOffsetSeconds: Int = 0
    ) throws {
        // Create Time with validation - Time.Error propagates naturally
        // This is correct: Time owns calendar validation, RFC 5322 delegates to it
        let time = try Time(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )

        self.init(time: time, timezoneOffset: Time.TimezoneOffset(seconds: timezoneOffsetSeconds))
    }
}

extension RFC_5322.DateTime {
    /// Seconds since Unix epoch (computed property for compatibility)
    public var secondsSinceEpoch: Int {
        time.secondsSinceEpoch
    }

    /// Timezone offset in seconds (computed property for compatibility)
    public var timezoneOffsetSeconds: Int {
        timezoneOffset.seconds
    }
}

// MARK: - Comparable

extension RFC_5322.DateTime {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.secondsSinceEpoch < rhs.secondsSinceEpoch
    }
}

// MARK: - Equatable & Hashable

extension RFC_5322.DateTime {
    /// Two DateTimes are equal if they represent the same moment in time
    /// (same secondsSinceEpoch), regardless of timezone offset
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.secondsSinceEpoch == rhs.secondsSinceEpoch
    }

    /// Hash based on the moment in time, not timezone display
    public func hash(into hasher: inout Hasher) {
        hasher.combine(secondsSinceEpoch)
    }
}

// MARK: - Components

extension RFC_5322.DateTime {
    /// Extract date components from date-time, adjusted for timezone offset
    public var components: RFC_5322.Date.Components {
        // Apply timezone offset to get local time
        let localTime = Time(secondsSinceEpoch: secondsSinceEpoch + timezoneOffsetSeconds)

        // Convert Time.Weekday to weekday number (0=Sunday)
        let weekdayNumber: Int
        switch localTime.weekday {
        case .sunday: weekdayNumber = 0
        case .monday: weekdayNumber = 1
        case .tuesday: weekdayNumber = 2
        case .wednesday: weekdayNumber = 3
        case .thursday: weekdayNumber = 4
        case .friday: weekdayNumber = 5
        case .saturday: weekdayNumber = 6
        }

        // Components calculated from valid epoch seconds are always valid
        // Use unchecked initializer to bypass validation in hot path
        return RFC_5322.Date.Components(
            __unchecked: (),
            year: localTime.year.rawValue,
            month: localTime.month.rawValue,
            day: localTime.day.rawValue,
            hour: localTime.hour.value,
            minute: localTime.minute.value,
            second: localTime.second.value,
            weekday: weekdayNumber
        )
    }
}

// MARK: - Constants

extension RFC_5322.DateTime {
    /// Month names per RFC 5322 section 3.3
    /// These are protocol-mandated values and must not be localized
    public static let monthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ]

    /// Day names per RFC 5322 section 3.3
    /// These are protocol-mandated values and must not be localized
    public static let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
}

// MARK: - Compositional Operations (Swifty monoid/functor-like behavior)

extension RFC_5322.DateTime {
    /// Returns a new DateTime by adding the specified number of seconds
    ///
    /// ## Example
    ///
    /// ```swift
    /// let dt = RFC_5322.DateTime(year: 2024, month: 1, day: 1)
    /// let tomorrow = dt.addingSeconds(86400)  // Add 1 day
    /// ```
    public func addingSeconds(_ seconds: Int) -> Self {
        Self(
            secondsSinceEpoch: secondsSinceEpoch + seconds,
            timezoneOffsetSeconds: timezoneOffsetSeconds
        )
    }

    /// Returns a new DateTime by subtracting the specified number of seconds
    public func subtractingSeconds(_ seconds: Int) -> Self {
        addingSeconds(-seconds)
    }

    /// Returns the time interval in seconds between this datetime and another
    ///
    /// Positive if `other` is later, negative if earlier.
    public func distance(to other: Self) -> Int {
        other.secondsSinceEpoch - secondsSinceEpoch
    }

    /// Returns a new DateTime with the timezone offset changed
    ///
    /// This creates a new view of the same instant in time with a different timezone.
    /// The underlying UTC moment remains the same.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let utc = RFC_5322.DateTime(year: 2024, month: 1, day: 1, hour: 12)
    /// let est = utc.withTimezone(offsetSeconds: -18000)  // UTC-5
    /// // Same moment, different display
    /// ```
    public func withTimezone(offsetSeconds: Int) -> Self {
        Self(secondsSinceEpoch: secondsSinceEpoch, timezoneOffsetSeconds: offsetSeconds)
    }

    /// Returns a new DateTime at the start of the day (00:00:00)
    public func startOfDay() -> Self {
        let components = self.components
        // swiftlint:disable:next force_try
        return try! Self(
            year: components.year,
            month: components.month,
            day: components.day,
            hour: 0,
            minute: 0,
            second: 0,
            timezoneOffsetSeconds: timezoneOffsetSeconds
        )
    }

    /// Returns a new DateTime at the end of the day (23:59:59)
    public func endOfDay() -> Self {
        let components = self.components
        // swiftlint:disable:next force_try
        return try! Self(
            year: components.year,
            month: components.month,
            day: components.day,
            hour: 23,
            minute: 59,
            second: 59,
            timezoneOffsetSeconds: timezoneOffsetSeconds
        )
    }

    /// Returns a new DateTime with the specified component values changed
    ///
    /// Use `nil` for components you want to keep unchanged.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let dt = RFC_5322.DateTime(year: 2024, month: 1, day: 15, hour: 10)
    /// let changed = try dt.setting(hour: 14, minute: 30)
    /// // Same day, different time
    /// ```
    public func setting(
        year: Int? = nil,
        month: Int? = nil,
        day: Int? = nil,
        hour: Int? = nil,
        minute: Int? = nil,
        second: Int? = nil
    ) throws -> Self {
        let current = components
        return try Self(
            year: year ?? current.year,
            month: month ?? current.month,
            day: day ?? current.day,
            hour: hour ?? current.hour,
            minute: minute ?? current.minute,
            second: second ?? current.second,
            timezoneOffsetSeconds: timezoneOffsetSeconds
        )
    }
}

// MARK: - Internal Arithmetic

extension RFC_5322.DateTime {
    /// Add a time interval to this date-time (internal - for timezone conversion)
    internal func adding(_ interval: Int) -> Self {
        Self(secondsSinceEpoch: secondsSinceEpoch + interval)
    }

    /// Subtract a time interval from this date-time (internal - for timezone conversion)
    internal func subtracting(_ interval: Int) -> Self {
        Self(secondsSinceEpoch: secondsSinceEpoch - interval)
    }
}

// MARK: - Codable

extension RFC_5322.DateTime: Codable {
    private enum CodingKeys: String, CodingKey {
        case secondsSinceEpoch
        case timezoneOffsetSeconds
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let seconds = try container.decode(Int.self, forKey: .secondsSinceEpoch)
        let offset = try container.decodeIfPresent(Int.self, forKey: .timezoneOffsetSeconds) ?? 0
        self.init(secondsSinceEpoch: seconds, timezoneOffsetSeconds: offset)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(secondsSinceEpoch, forKey: .secondsSinceEpoch)
        try container.encode(timezoneOffsetSeconds, forKey: .timezoneOffsetSeconds)
    }
}

// MARK: - CustomStringConvertible
