// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let rfc5322: Self = "RFC_5322"
}

extension Target.Dependency {
    static var rfc5322: Self { .target(name: .rfc5322) }
    static var rfc1123: Self { .product(name: "RFC_1123", package: "swift-rfc-1123") }
    static var rfc5321: Self { .product(name: "RFC_5321", package: "swift-rfc-5321") }
}

let package = Package(
    name: "swift-rfc-5322",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: .rfc5322, targets: [.rfc5322]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-rfc-1123.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-standards/swift-rfc-5321.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: .rfc5322,
            dependencies: [
                .rfc1123,
                .rfc5321
            ]
        ),
        .testTarget(
            name: .rfc5322.tests,
            dependencies: [
                .rfc5322
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String { var tests: Self { self + " Tests" } }