//
//  RFC_5322.Parse.DateTime.swift
//  swift-rfc-5322
//
//  RFC 5322 date-time: [day-of-week ","] date time
//

public import Parser_Primitives

extension RFC_5322.Parse {
    /// Parses an RFC 5322 date-time per Section 3.3.
    ///
    /// `date-time = [ day-of-week "," ] date time [CFWS]`
    /// `date      = day month year`
    /// `time      = time-of-day zone`
    ///
    /// Example: `Mon, 15 Jan 2024 12:30:00 +0000`
    ///
    /// Returns raw byte slices for each component. Interpretation of
    /// month names and timezone abbreviations is left to the caller.
    public struct DateTime<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_5322.Parse.DateTime {
    public struct Output: Sendable {
        /// Day of week (3-letter abbreviation), if present
        public let dayOfWeek: Input?
        /// Day of month
        public let day: Int
        /// Month (3-letter abbreviation as raw bytes)
        public let month: Input
        /// Year
        public let year: Int
        /// Hour
        public let hour: Int
        /// Minute
        public let minute: Int
        /// Second (0 if not present)
        public let second: Int
        /// Timezone as raw bytes (e.g., "+0000", "EST")
        public let timezone: Input

        @inlinable
        public init(
            dayOfWeek: Input?, day: Int, month: Input, year: Int,
            hour: Int, minute: Int, second: Int, timezone: Input
        ) {
            self.dayOfWeek = dayOfWeek
            self.month = month
            self.day = day
            self.year = year
            self.hour = hour
            self.minute = minute
            self.second = second
            self.timezone = timezone
        }
    }

    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedDigit
        case expectedMonth
        case expectedColon
        case expectedTimezone
        case unexpectedEndOfInput
    }
}

extension RFC_5322.Parse.DateTime: Parser.`Protocol` {
    public typealias ParseOutput = Output
    public typealias Failure = RFC_5322.Parse.DateTime<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        Self._skipCFWS(&input)

        // Optional day-of-week (3 alpha followed by ',')
        var dayOfWeek: Input? = nil
        let saved = input
        if let dow = Self._tryDayOfWeek(&input) {
            dayOfWeek = dow
        } else {
            input = saved
        }

        Self._skipCFWS(&input)

        // Day (1 or 2 digits)
        let day = try Self._parseNumber(&input)

        Self._skipCFWS(&input)

        // Month (3-letter abbreviation)
        let month = try Self._parseAlpha(&input, count: 3)

        Self._skipCFWS(&input)

        // Year (2 or 4 digits)
        let year = try Self._parseNumber(&input)

        Self._skipCFWS(&input)

        // Hour
        let hour = try Self._parseNumber(&input)

        // ':'
        guard input.startIndex < input.endIndex, input[input.startIndex] == 0x3A else {
            throw .expectedColon
        }
        input = input[input.index(after: input.startIndex)...]

        // Minute
        let minute = try Self._parseNumber(&input)

        // Optional ':' + second
        var second = 0
        if input.startIndex < input.endIndex && input[input.startIndex] == 0x3A {
            input = input[input.index(after: input.startIndex)...]
            second = try Self._parseNumber(&input)
        }

        Self._skipCFWS(&input)

        // Timezone (consume remaining non-whitespace)
        let tzStart = input.startIndex
        while input.startIndex < input.endIndex {
            let byte = input[input.startIndex]
            if byte == 0x20 || byte == 0x09 || byte == 0x0D || byte == 0x0A { break }
            input = input[input.index(after: input.startIndex)...]
        }
        guard tzStart < input.startIndex else { throw .expectedTimezone }
        let timezone = input[tzStart..<input.startIndex]

        Self._skipCFWS(&input)

        return Output(
            dayOfWeek: dayOfWeek, day: day, month: month, year: year,
            hour: hour, minute: minute, second: second, timezone: timezone
        )
    }

    @inlinable
    static func _skipCFWS(_ input: inout Input) {
        while input.startIndex < input.endIndex {
            let byte = input[input.startIndex]
            guard byte == 0x20 || byte == 0x09 || byte == 0x0D || byte == 0x0A else { break }
            input = input[input.index(after: input.startIndex)...]
        }
    }

    @inlinable
    static func _tryDayOfWeek(_ input: inout Input) -> Input? {
        var idx = input.startIndex
        var count = 0
        while idx < input.endIndex && count < 3 {
            let byte = input[idx]
            guard (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A) else {
                return nil
            }
            input.formIndex(after: &idx)
            count += 1
        }
        guard count == 3 else { return nil }
        let dow = input[input.startIndex..<idx]
        // Expect ','
        guard idx < input.endIndex && input[idx] == 0x2C else { return nil }
        input.formIndex(after: &idx)
        input = input[idx...]
        return dow
    }

    @inlinable
    static func _parseNumber(_ input: inout Input) throws(Failure) -> Int {
        var value = 0
        var count = 0
        while input.startIndex < input.endIndex {
            let byte = input[input.startIndex]
            guard byte >= 0x30 && byte <= 0x39 else { break }
            value = value &* 10 &+ Int(byte &- 0x30)
            input = input[input.index(after: input.startIndex)...]
            count += 1
        }
        guard count > 0 else { throw .expectedDigit }
        return value
    }

    @inlinable
    static func _parseAlpha(_ input: inout Input, count: Int) throws(Failure) -> Input {
        let start = input.startIndex
        var idx = start
        var n = 0
        while idx < input.endIndex && n < count {
            let byte = input[idx]
            guard (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A) else {
                throw .expectedMonth
            }
            input.formIndex(after: &idx)
            n += 1
        }
        guard n == count else { throw .expectedMonth }
        let result = input[start..<idx]
        input = input[idx...]
        return result
    }
}
