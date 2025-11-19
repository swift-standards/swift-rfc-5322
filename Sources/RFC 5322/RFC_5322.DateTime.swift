// DateTime.swift
// RFC 5322
//
// RFC 5322 date-time representation and formatting
// Format: "Mon, 01 Jan 2024 12:34:56 +0000"

public import Standards
public import Time

extension RFC_5322 {

    public typealias Date = DateTime

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

        /// Create a date-time from seconds since epoch
        /// - Parameters:
        ///   - secondsSinceEpoch: Seconds since Unix epoch (UTC)
        ///   - timezoneOffsetSeconds: Timezone offset in seconds (default: 0 for UTC)
        public init(secondsSinceEpoch: Int, timezoneOffsetSeconds: Int = 0) {
            self.time = Time(secondsSinceEpoch: secondsSinceEpoch)
            self.timezoneOffset = Time.TimezoneOffset(seconds: timezoneOffsetSeconds)
        }

        /// Seconds since Unix epoch (computed property for compatibility)
        public var secondsSinceEpoch: Int {
            time.secondsSinceEpoch
        }

        /// Timezone offset in seconds (computed property for compatibility)
        public var timezoneOffsetSeconds: Int {
            timezoneOffset.seconds
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
            uncheckedYear: localTime.year.value,
            month: localTime.month.value,
            day: localTime.day.value,
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
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]

    /// Day names per RFC 5322 section 3.3
    /// These are protocol-mandated values and must not be localized
    public static let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
}

// MARK: - DateTime Formatter (Separated formatting logic)

extension RFC_5322.DateTime {
    /// Dedicated formatter for RFC 5322 date-time strings
    ///
    /// Separates formatting logic from the data model, following protocol witness pattern.
    /// Format: "Mon, 01 Jan 2024 12:34:56 +0000"
    ///
    /// ## Example
    ///
    /// ```swift
    /// let dt = RFC_5322.DateTime(year: 2024, month: 1, day: 1)
    /// let formatted = RFC_5322.DateTime.Formatter.format(dt)
    /// ```
    public enum Formatter {
        /// Formats a date-time as RFC 5322 date-time string
        /// Optimized implementation avoiding multiple formatter allocations
        public static func format(_ value: RFC_5322.DateTime) -> String {
            let components = value.components

            let dayName = RFC_5322.DateTime.dayNames[components.weekday]
            let monthName = RFC_5322.DateTime.monthNames[components.month - 1]

            // Manually format numbers with zero-padding to avoid formatter overhead
            let day = formatTwoDigits(components.day)
            let year = formatFourDigits(components.year)
            let hour = formatTwoDigits(components.hour)
            let minute = formatTwoDigits(components.minute)
            let second = formatTwoDigits(components.second)

            // Format timezone offset
            let offsetSign = value.timezoneOffsetSeconds >= 0 ? "+" : "-"
            let offsetHours = abs(value.timezoneOffsetSeconds) / Time.Calendar.Gregorian.TimeConstants.secondsPerHour
            let offsetMinutes = (abs(value.timezoneOffsetSeconds) % Time.Calendar.Gregorian.TimeConstants.secondsPerHour) / Time.Calendar.Gregorian.TimeConstants.secondsPerMinute
            let timezone = "\(offsetSign)\(formatTwoDigits(offsetHours))\(formatTwoDigits(offsetMinutes))"

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
}

// MARK: - Swift-Native Formatting

extension RFC_5322.DateTime {
    /// Formats this date-time as an RFC 5322 date-time string
    ///
    /// This method provides a Swift-native formatting interface without protocol dependencies.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let dt = try RFC_5322.DateTime(year: 2024, month: 1, day: 1)
    /// let formatted = dt.formatted()  // "Mon, 01 Jan 2024 00:00:00 +0000"
    /// ```
    public func formatted() -> String {
        Formatter.format(self)
    }

    /// Formats a date-time as RFC 5322 date-time string
    /// Legacy method for protocol compatibility
    public func format(_ value: Self) -> String {
        Formatter.format(value)
    }
}

// MARK: - DateTime Parser (Separated parsing logic)

extension RFC_5322.DateTime {
    /// Dedicated parser for RFC 5322 date-time strings
    ///
    /// Separates parsing logic from the data model, following protocol witness pattern.
    /// Supports formats:
    /// - "Mon, 01 Jan 2024 12:34:56 +0000" (with seconds)
    /// - "Mon, 01 Jan 2024 12:34 +0000" (without seconds)
    /// - Timezone offsets like +0000, -0500, etc.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let dt = try RFC_5322.DateTime.Parser.parse("Mon, 01 Jan 2024 12:00:00 +0000")
    /// ```
    public enum Parser {
        /// Parse RFC 5322 date-time string
        /// - Parameter value: The RFC 5322 date-time string
        /// - Returns: DateTime
        /// - Throws: RFC_5322.Date.Error if parsing fails
        public static func parse(_ value: String) throws -> RFC_5322.DateTime {
        // Split into components
        let parts = value.split(separator: " ").map(String.init)

        // Expect at least 6 parts: "Mon," "01" "Jan" "2024" "12:34:56" "+0000"
        // or 6 parts for no seconds: "Mon," "01" "Jan" "2024" "12:34" "+0000"
        guard parts.count >= 6 else {
            throw RFC_5322.Date.Error.invalidFormat("Expected at least 6 components")
        }

        // Parse day name (optional, for validation)
        let dayName = parts[0].split(separator: ",").map(String.init).first ?? parts[0]
        guard let expectedWeekday = RFC_5322.DateTime.dayNames.firstIndex(of: dayName) else {
            throw RFC_5322.Date.Error.invalidDayName(dayName)
        }

        // Parse day
        guard let day = Int(parts[1]), day >= 1, day <= 31 else {
            throw RFC_5322.Date.Error.invalidDay(parts[1])
        }

        // Parse month
        guard let monthIndex = RFC_5322.DateTime.monthNames.firstIndex(of: parts[2]) else {
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

        let timezoneOffsetSeconds = sign * (
            offsetHours * Time.Calendar.Gregorian.TimeConstants.secondsPerHour +
            offsetMinutes * Time.Calendar.Gregorian.TimeConstants.secondsPerMinute
        )

        // Create date-time in UTC with validated components
        let dateTime = try RFC_5322.DateTime(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )

        // Adjust for timezone offset to get UTC
        // If timezone is +0500, we subtract 5 hours to get UTC
        let utcDateTime = dateTime.subtracting(timezoneOffsetSeconds)

        // Validate weekday matches (using the local time components)
        let localDateTime = RFC_5322.DateTime(secondsSinceEpoch: utcDateTime.secondsSinceEpoch, timezoneOffsetSeconds: timezoneOffsetSeconds)
        let actualWeekday = localDateTime.components.weekday
        guard actualWeekday == expectedWeekday else {
            throw RFC_5322.Date.Error.weekdayMismatch(
                expected: RFC_5322.DateTime.dayNames[expectedWeekday],
                actual: RFC_5322.DateTime.dayNames[actualWeekday]
            )
        }

        return localDateTime
        }
    }
}

// MARK: - Swift-Native Parsing

extension RFC_5322.DateTime {
    /// Creates a date-time by parsing an RFC 5322 date-time string
    ///
    /// This initializer provides a Swift-native parsing interface without protocol dependencies.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let dt = try RFC_5322.DateTime(parsing: "Mon, 01 Jan 2024 12:00:00 +0000")
    /// ```
    ///
    /// - Parameter string: The RFC 5322 date-time string to parse
    /// - Throws: `RFC_5322.Date.Error` if parsing fails
    public init(parsing string: String) throws {
        self = try Parser.parse(string)
    }

    /// Parse RFC 5322 date-time string
    /// Legacy method for protocol compatibility
    public func parse(_ value: String) throws -> Self {
        try Parser.parse(value)
    }
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
        Self(secondsSinceEpoch: secondsSinceEpoch + seconds, timezoneOffsetSeconds: timezoneOffsetSeconds)
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

extension RFC_5322.DateTime: CustomStringConvertible {
    public var description: String {
        formatted()
    }
}
