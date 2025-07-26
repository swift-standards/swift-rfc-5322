//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 26/12/2024.
//

import Foundation

extension RFC_5322 {
    public enum Date {}
}

extension RFC_5322.Date {
    // MARK: - RFC 5322 Constants
    /// Valid year range as specified by RFC 5322 (1900 or later)
    private static let validYearRange = 1900...9999

    /// Month abbreviations as specified by RFC 5322 section 3.3
    /// These are protocol-mandated values and must not be localized
    public static let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    /// Day abbreviations as specified by RFC 5322 section 3.3
    /// These are protocol-mandated values and must not be localized
    public static let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // MARK: - Date Formatter
    public static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // Allow both with and without seconds
        formatter.defaultDate = nil
        formatter.dateFormat = "EEE', 'dd' 'MMM' 'yyyy' 'HH:mm:ss' 'Z"
        if #available(macOS 13, *) {
            formatter.timeZone = .gmt
        } else {
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
        }
        return formatter
    }()

    // Secondary formatter for when seconds are omitted
    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.defaultDate = nil
        formatter.dateFormat = "EEE', 'dd' 'MMM' 'yyyy' 'HH:mm' 'Z"
        if #available(macOS 13, *) {
            formatter.timeZone = .gmt
        } else {
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
        }
        return formatter
    }()

    /// Format a `Date` into RFC5322-compliant string
    public static func string(from date: Foundation.Date) -> String {
        formatter.string(from: date)
    }

    /// Parse an RFC5322-compliant string into a `Foundation.Date`
    public static func date(from string: String) throws -> Foundation.Date {
        // Try parsing with seconds first
        if let date = formatter.date(from: string) {
            if isValidDate(string, date: date) {
                return date
            }
        }

        // Try parsing without seconds
        if let date = shortFormatter.date(from: string) {
            if isValidDate(string, date: date) {
                return date
            }
        }

        throw DateError.invalidDate(string)
    }

    // MARK: - Validation
    private static func isValidDate(_ dateString: String, date: Foundation.Date) -> Bool {
        let components = dateString.components(separatedBy: " ")
        guard components.count >= 6 else { return false }

        // Validate day of week if present
        if let dayOfWeek = components.first?.replacingOccurrences(of: ",", with: "") {
            if !Self.days.contains(dayOfWeek) {
                return false
            }

            // Verify day matches the date
            let calendar = Calendar(identifier: .gregorian)
            let weekday = calendar.component(.weekday, from: date)
            let expectedDay = Self.days[(weekday + 5) % 7]
            if dayOfWeek != expectedDay {
                return false
            }
        }

        // Validate month
        guard let monthStr = components.dropFirst(2).first,
              Self.months.contains(monthStr) else {
            return false
        }

        // Validate year
        guard let yearStr = components.dropFirst(3).first,
              let year = Int(yearStr),
              validYearRange.contains(year) else {
            return false
        }

        // Validate time format
        let timeComponents = components[4].split(separator: ":")
        guard timeComponents.count >= 2,
              timeComponents.count <= 3,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]),
              hour >= 0 && hour <= 23,
              minute >= 0 && minute <= 59 else {
            return false
        }

        if timeComponents.count == 3 {
            guard let second = Int(timeComponents[2]),
                  second >= 0 && second <= 60 else { // Allow for leap second
                return false
            }
        }

        // Validate timezone
        let zone = components.last ?? ""
        guard zone.count == 5,
              zone.hasPrefix("+") || zone.hasPrefix("-"),
              let offset = Int(zone.dropFirst()),
              offset <= 9959 else {
            return false
        }

        return true
    }

    // MARK: - Error Type
    public enum DateError: Error {
        case invalidDate(String)
    }
}

@available(macOS 12.0, *)
extension FormatStyle where Self == Foundation.Date.FormatStyle {
    public static var rfc5322: RFC5322DateStyle {
        RFC5322DateStyle()
    }
}

@available(macOS 12.0, *)
public struct RFC5322DateStyle: FormatStyle {
    public typealias FormatInput = Foundation.Date
    public typealias FormatOutput = String

    public func format(_ value: Foundation.Date) -> String {
        RFC_5322.Date.string(from: value)
    }
}
