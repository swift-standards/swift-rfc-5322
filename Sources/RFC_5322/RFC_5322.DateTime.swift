// DateTime.swift
// RFC 5322
//
// RFC 5322 date-time representation and formatting
// Format: "Mon, 01 Jan 2024 12:34:56 +0000"

import Standards
import Formatting

// MARK: - Time Constants

private enum TimeConstants {
    static let secondsPerMinute = 60
    static let secondsPerHour = 3600
    static let secondsPerDay = 86400
    static let daysPerCommonYear = 365
    static let daysPerLeapYear = 366
}

extension RFC_5322 {

    public typealias Date = DateTime

    /// RFC 5322 date-time representation
    ///
    /// Represents a date-time value per RFC 5322 section 3.3.
    /// The RFC calls this a "date-time" (not "timestamp" or "date").
    /// Stores seconds since Unix epoch (1970-01-01 00:00:00 UTC) internally.
    ///
    /// Example:
    /// ```swift
    /// let dateTime = RFC_5322.DateTime(year: 2024, month: 1, day: 1, hour: 12, minute: 30)
    /// print(dateTime.format(dateTime))  // "Mon, 01 Jan 2024 12:30:00 +0000"
    /// ```
    public struct DateTime: Sendable, Equatable, Hashable, Comparable {
        /// Seconds since Unix epoch (1970-01-01 00:00:00 UTC)
        public let secondsSinceEpoch: Double

        /// Timezone offset in seconds from UTC
        /// Positive values are east of UTC, negative values are west
        /// Example: +0100 = 3600, -0500 = -18000
        public let timezoneOffsetSeconds: Int

        /// Create a date-time from seconds since epoch
        /// - Parameters:
        ///   - secondsSinceEpoch: Seconds since Unix epoch (UTC)
        ///   - timezoneOffsetSeconds: Timezone offset in seconds (default: 0 for UTC)
        public init(secondsSinceEpoch: Double = 0, timezoneOffsetSeconds: Int = 0) {
            self.secondsSinceEpoch = secondsSinceEpoch
            self.timezoneOffsetSeconds = timezoneOffsetSeconds
        }
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

// MARK: - Additional Initializers

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
        day: Int,    // 1-31
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        timezoneOffsetSeconds: Int = 0
    ) throws {
        // Validate all components by attempting to create Components
        // This provides consistent validation logic
        let weekday = Self.weekday(year: year, month: month, day: day)
        _ = try RFC_5322.Date.Components(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            weekday: weekday
        )

        // Calculate days since epoch
        let daysSinceEpoch = Self.daysSinceEpoch(year: year, month: month, day: day)

        // Calculate total seconds (as UTC)
        let totalSeconds = Double(
            daysSinceEpoch * TimeConstants.secondsPerDay +
            hour * TimeConstants.secondsPerHour +
            minute * TimeConstants.secondsPerMinute +
            second
        )

        self.init(secondsSinceEpoch: totalSeconds, timezoneOffsetSeconds: timezoneOffsetSeconds)
    }
}

// MARK: - Components

extension RFC_5322.DateTime {
    /// Extract date components from date-time, adjusted for timezone offset
    public var components: RFC_5322.Date.Components {
        // Apply timezone offset to get local time
        let localSeconds = secondsSinceEpoch + Double(timezoneOffsetSeconds)
        let totalSeconds = Int(localSeconds)
        let totalDays = totalSeconds / TimeConstants.secondsPerDay
        let secondsInDay = totalSeconds % TimeConstants.secondsPerDay

        let hour = secondsInDay / TimeConstants.secondsPerHour
        let minute = (secondsInDay % TimeConstants.secondsPerHour) / TimeConstants.secondsPerMinute
        let second = secondsInDay % TimeConstants.secondsPerMinute

        // Calculate year, month, day from days since epoch
        // Optimized O(1) year calculation instead of O(n) loop
        let (year, remainingDays) = Self.yearAndDays(fromDaysSinceEpoch: totalDays)

        // Calculate month and day
        let daysInMonths = Self.daysInMonths(year: year)
        var month = 1
        var daysInCurrentMonth = remainingDays
        for daysInMonth in daysInMonths {
            if daysInCurrentMonth < daysInMonth {
                break
            }
            daysInCurrentMonth -= daysInMonth
            month += 1
        }

        let day = daysInCurrentMonth + 1

        // Components calculated from valid epoch seconds should always be valid
        // Using try! is safe here as this is an internal invariant
        return try! RFC_5322.Date.Components(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            weekday: Self.weekday(year: year, month: month, day: day)
        )
    }
}

// MARK: - Constants

extension RFC_5322.DateTime {
    /// Month names per RFC 5322 section 3.3
    /// These are protocol-mandated values and must not be localized
    public static let monthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]

    /// Day names per RFC 5322 section 3.3
    /// These are protocol-mandated values and must not be localized
    public static let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
}

// MARK: - Formatting Protocol

extension RFC_5322.DateTime: Formatting {
    /// Formats a date-time as RFC 5322 date-time string
    /// Format: "Mon, 01 Jan 2024 12:34:56 +0000"
    /// Optimized implementation avoiding multiple formatter allocations
    public func format(_ value: Self) -> String {
        let components = value.components

        let dayName = Self.dayNames[components.weekday]
        let monthName = Self.monthNames[components.month - 1]

        // Manually format numbers with zero-padding to avoid formatter overhead
        let day = Self.formatTwoDigits(components.day)
        let year = Self.formatFourDigits(components.year)
        let hour = Self.formatTwoDigits(components.hour)
        let minute = Self.formatTwoDigits(components.minute)
        let second = Self.formatTwoDigits(components.second)

        // Format timezone offset
        let offsetSign = value.timezoneOffsetSeconds >= 0 ? "+" : "-"
        let offsetHours = abs(value.timezoneOffsetSeconds) / TimeConstants.secondsPerHour
        let offsetMinutes = (abs(value.timezoneOffsetSeconds) % TimeConstants.secondsPerHour) / TimeConstants.secondsPerMinute
        let timezone = "\(offsetSign)\(Self.formatTwoDigits(offsetHours))\(Self.formatTwoDigits(offsetMinutes))"

        return "\(dayName), \(day) \(monthName) \(year) \(hour):\(minute):\(second) \(timezone)"
    }

    /// Fast two-digit zero-padded formatting (00-99)
    private static func formatTwoDigits(_ value: Int) -> String {
        let tens = value / 10
        let ones = value % 10
        return "\(tens)\(ones)"
    }

    /// Fast four-digit zero-padded formatting (0000-9999)
    private static func formatFourDigits(_ value: Int) -> String {
        let thousands = value / 1000
        let hundreds = (value % 1000) / 100
        let tens = (value % 100) / 10
        let ones = value % 10
        return "\(thousands)\(hundreds)\(tens)\(ones)"
    }
}
// MARK: - Parsing

extension RFC_5322.DateTime: Format.Parsing {
    /// Parse RFC 5322 date-time string
    /// Supports formats:
    /// - "Mon, 01 Jan 2024 12:34:56 +0000" (with seconds)
    /// - "Mon, 01 Jan 2024 12:34 +0000" (without seconds)
    /// - Timezone offsets like +0000, -0500, etc.
    ///
    /// - Parameter value: The RFC 5322 date-time string
    /// - Returns: DateTime
    /// - Throws: RFC_5322.Date.Error if parsing fails
    public func parse(_ value: String) throws -> Self {
        // Split into components
        let parts = value.split(separator: " ").map(String.init)

        // Expect at least 6 parts: "Mon," "01" "Jan" "2024" "12:34:56" "+0000"
        // or 6 parts for no seconds: "Mon," "01" "Jan" "2024" "12:34" "+0000"
        guard parts.count >= 6 else {
            throw RFC_5322.Date.Error.invalidFormat("Expected at least 6 components")
        }

        // Parse day name (optional, for validation)
        let dayName = parts[0].split(separator: ",").map(String.init).first ?? parts[0]
        guard let expectedWeekday = Self.dayNames.firstIndex(of: dayName) else {
            throw RFC_5322.Date.Error.invalidDayName(dayName)
        }

        // Parse day
        guard let day = Int(parts[1]), day >= 1, day <= 31 else {
            throw RFC_5322.Date.Error.invalidDay(parts[1])
        }

        // Parse month
        guard let monthIndex = Self.monthNames.firstIndex(of: parts[2]) else {
            throw RFC_5322.Date.Error.invalidMonth(parts[2])
        }
        let month = monthIndex + 1

        // Parse year
        guard let year = Int(parts[3]), year >= 1900 else {
            throw RFC_5322.Date.Error.invalidYear(parts[3])
        }

        // Parse time (HH:MM:SS or HH:MM)
        let timeParts = parts[4].split(separator: ":").map(String.init)
        guard timeParts.count >= 2, timeParts.count <= 3 else {
            throw RFC_5322.Date.Error.invalidTime(parts[4])
        }

        guard let hour = Int(timeParts[0]), hour >= 0, hour <= 23 else {
            throw RFC_5322.Date.Error.invalidHour(timeParts[0])
        }

        guard let minute = Int(timeParts[1]), minute >= 0, minute <= 59 else {
            throw RFC_5322.Date.Error.invalidMinute(timeParts[1])
        }

        let second: Int
        if timeParts.count == 3 {
            guard let sec = Int(timeParts[2]), sec >= 0, sec <= 60 else {  // Allow leap second
                throw RFC_5322.Date.Error.invalidSecond(timeParts[2])
            }
            second = sec
        } else {
            second = 0
        }

        // Parse timezone offset
        let timezoneString = parts[5]
        guard timezoneString.count == 5 else {
            throw RFC_5322.Date.Error.invalidTimezone(timezoneString)
        }

        let sign = timezoneString.first == "+" ? 1 : -1
        let offsetString = String(timezoneString.dropFirst())

        guard offsetString.count == 4,
              let offsetHours = Int(offsetString.prefix(2)),
              let offsetMinutes = Int(offsetString.suffix(2)),
              offsetHours >= 0, offsetHours <= 23,
              offsetMinutes >= 0, offsetMinutes <= 59
        else {
            throw RFC_5322.Date.Error.invalidTimezone(timezoneString)
        }

        let timezoneOffsetSeconds = sign * (offsetHours * 3600 + offsetMinutes * 60)

        // Create date-time in UTC with validated components
        let dateTime = try Self(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )

        // Adjust for timezone offset to get UTC
        // If timezone is +0500, we subtract 5 hours to get UTC
        let utcDateTime = dateTime.subtracting(Double(timezoneOffsetSeconds))

        // Validate weekday matches (using the local time components)
        let localDateTime = Self(secondsSinceEpoch: utcDateTime.secondsSinceEpoch, timezoneOffsetSeconds: timezoneOffsetSeconds)
        let actualWeekday = localDateTime.components.weekday
        guard actualWeekday == expectedWeekday else {
            throw RFC_5322.Date.Error.weekdayMismatch(
                expected: Self.dayNames[expectedWeekday],
                actual: Self.dayNames[actualWeekday]
            )
        }

        return localDateTime
    }
}


// MARK: - Internal Arithmetic

extension RFC_5322.DateTime {
    /// Add a time interval to this date-time (internal - for timezone conversion)
    internal func adding(_ interval: Double) -> Self {
        Self(secondsSinceEpoch: secondsSinceEpoch + interval)
    }

    /// Subtract a time interval from this date-time (internal - for timezone conversion)
    internal func subtracting(_ interval: Double) -> Self {
        Self(secondsSinceEpoch: secondsSinceEpoch - interval)
    }
}

// MARK: - Private Helpers

extension RFC_5322.DateTime {
    private static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }

    // Cached arrays to avoid allocation on every call
    private static let daysInCommonYearMonths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    private static let daysInLeapYearMonths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    private static func daysInMonths(year: Int) -> [Int] {
        isLeapYear(year) ? daysInLeapYearMonths : daysInCommonYearMonths
    }

    /// Optimized O(1) calculation of year and remaining days from days since epoch
    /// Avoids O(n) loop iteration through years
    private static func yearAndDays(fromDaysSinceEpoch days: Int) -> (year: Int, remainingDays: Int) {
        // Use 400-year cycle for leap year calculation
        // Every 400 years has exactly: 400*365 + 97 leap days = 146097 days
        let cyclesOf400 = days / 146097
        let remainingDays = days % 146097
        let year = 1970 + cyclesOf400 * 400

        // Handle remaining years (less than 400)
        // Approximate with average year length, then refine
        var approximateYear = year + (remainingDays / TimeConstants.daysPerCommonYear)

        // Refine: calculate exact days to approximateYear
        var daysToYear = 0
        for y in year..<approximateYear {
            daysToYear += isLeapYear(y) ? TimeConstants.daysPerLeapYear : TimeConstants.daysPerCommonYear
        }

        // Adjust if we overshot
        while daysToYear > remainingDays {
            approximateYear -= 1
            daysToYear -= isLeapYear(approximateYear) ? TimeConstants.daysPerLeapYear : TimeConstants.daysPerCommonYear
        }

        // Adjust if we undershot
        while daysToYear + (isLeapYear(approximateYear) ? TimeConstants.daysPerLeapYear : TimeConstants.daysPerCommonYear) <= remainingDays {
            daysToYear += isLeapYear(approximateYear) ? TimeConstants.daysPerLeapYear : TimeConstants.daysPerCommonYear
            approximateYear += 1
        }

        return (approximateYear, remainingDays - daysToYear)
    }

    private static func daysSinceEpoch(year: Int, month: Int, day: Int) -> Int {
        // Optimized calculation avoiding year-by-year iteration
        let yearsSince1970 = year - 1970

        // Calculate leap years between 1970 and year (exclusive)
        // Count years divisible by 4, subtract those divisible by 100, add back those divisible by 400
        let leapYears: Int
        if yearsSince1970 > 0 {
            let yearBefore = year - 1
            leapYears = (yearBefore / 4 - 1970 / 4) -
                        (yearBefore / 100 - 1970 / 100) +
                        (yearBefore / 400 - 1970 / 400)
        } else {
            leapYears = 0
        }

        var days = yearsSince1970 * TimeConstants.daysPerCommonYear + leapYears

        // Add days for complete months in current year
        let monthDays = daysInMonths(year: year)
        for m in 0..<(month - 1) {
            days += monthDays[m]
        }

        // Add remaining days
        days += day - 1

        return days
    }

    /// Calculate day of week (0 = Sunday, 6 = Saturday)
    /// Using Zeller's congruence algorithm
    private static func weekday(year: Int, month: Int, day: Int) -> Int {
        var y = year
        var m = month

        if m < 3 {
            m += 12
            y -= 1
        }

        let q = day
        let K = y % 100
        let J = y / 100

        let h = (q + ((13 * (m + 1)) / 5) + K + (K / 4) + (J / 4) - (2 * J)) % 7

        // Convert from Zeller's (0=Saturday) to our (0=Sunday)
        return (h + 6) % 7
    }
}


// MARK: - Codable

extension RFC_5322.DateTime: Codable {
    private enum CodingKeys: String, CodingKey {
        case secondsSinceEpoch
        case timezoneOffsetSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let seconds = try container.decode(Double.self, forKey: .secondsSinceEpoch)
        let offset = try container.decodeIfPresent(Int.self, forKey: .timezoneOffsetSeconds) ?? 0
        self.init(secondsSinceEpoch: seconds, timezoneOffsetSeconds: offset)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(secondsSinceEpoch, forKey: .secondsSinceEpoch)
        try container.encode(timezoneOffsetSeconds, forKey: .timezoneOffsetSeconds)
    }
}

// MARK: - CustomStringConvertible

extension RFC_5322.DateTime: CustomStringConvertible {
    public var description: String {
        format(self)
    }
}
