//
//  RFC_5322.DateTime PerformanceTests.swift
//  RFC 5322 Tests
//
//  Performance tests for RFC_5322.DateTime
//

import Testing
import StandardsTestSupport
@testable import RFC_5322

extension PerformanceTests {
    @Suite(.serialized)
    struct DateTimePerformance {

        // MARK: - Construction Performance

        @Test(.timed(iterations: 10000, warmup: 1000, threshold: .microseconds(90)))
        func `create from epoch`() {
            _ = RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(90)))
        func `create from components`() throws {
            _ = try RFC_5322.DateTime(
                year: 2024,
                month: 1,
                day: 15,
                hour: 12,
                minute: 30,
                second: 45
            )
        }

        // MARK: - Components Extraction Performance

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(100), metric: .median))
        func `extract components from UTC datetime`() {
            let dateTime = RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
            _ = dateTime.components
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(100), metric: .median))
        func `extract components with timezone offset`() {
            let dateTime = RFC_5322.DateTime(
                secondsSinceEpoch: 1609459200,
                timezoneOffsetSeconds: 3600
            )
            _ = dateTime.components
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(120), metric: .median))
        func `extract components for far future date`() throws {
            let dateTime = try RFC_5322.DateTime(
                year: 2100,
                month: 12,
                day: 31
            )
            _ = dateTime.components
        }

        // MARK: - Formatting Performance

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(110)))
        func `format datetime to string`() throws {
            let dateTime = try RFC_5322.DateTime(
                year: 2024,
                month: 1,
                day: 15,
                hour: 12,
                minute: 30
            )
            _ = String(dateTime)
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(110)))
        func `format datetime with timezone`() throws {
            let dateTime = try RFC_5322.DateTime(
                year: 2024,
                month: 1,
                day: 15,
                hour: 12,
                minute: 30,
                timezoneOffsetSeconds: 3600
            )
            _ = String(dateTime)
        }

        // MARK: - Parsing Performance

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(115)))
        func `parse datetime string`() throws {
            let parser = RFC_5322.DateTime(secondsSinceEpoch: 0)
            _ = try parser.parse("Fri, 01 Jan 2021 12:00:00 +0000")
        }

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(115)))
        func `parse datetime with timezone offset`() throws {
            let parser = RFC_5322.DateTime(secondsSinceEpoch: 0)
            _ = try parser.parse("Mon, 15 Jan 2024 14:30:00 +0500")
        }

        // MARK: - Byte Conversion Performance

        @Test(.timed(iterations: 1000, warmup: 100, threshold: .microseconds(105)))
        func `convert to bytes`() throws {
            let dateTime = try RFC_5322.DateTime(
                year: 2024,
                month: 1,
                day: 15,
                hour: 12,
                minute: 30
            )
            _ = [UInt8](dateTime)
        }

        // MARK: - Comparison Performance

        @Test(.timed(iterations: 10000, warmup: 1000, threshold: .microseconds(95)))
        func `compare datetimes`() {
            let earlier = RFC_5322.DateTime(secondsSinceEpoch: 1000)
            let later = RFC_5322.DateTime(secondsSinceEpoch: 2000)
            _ = earlier < later
        }

        @Test(.timed(iterations: 10000, warmup: 1000, threshold: .microseconds(95)))
        func `check datetime equality`() {
            let dt1 = RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
            let dt2 = RFC_5322.DateTime(secondsSinceEpoch: 1609459200)
            _ = dt1 == dt2
        }
    }
}
