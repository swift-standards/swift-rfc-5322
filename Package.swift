// swift-tools-version:6.0

import PackageDescription

extension String {
    static let rfc5322: Self = "RFC_5322"
    static let rfc5322Foundation: Self = "RFC_5322_Foundation"
}

extension String { var tests: Self { self + " Tests" } }

extension Target.Dependency {
    static var rfc5322: Self { .target(name: .rfc5322) }
    static var rfc5322Foundation: Self { .target(name: .rfc5322Foundation) }
    static var rfc1123: Self { .product(name: "RFC_1123", package: "swift-rfc-1123") }
    static var standards: Self { .product(name: "Standards", package: "swift-standards") }
    static var incits_4_1986: Self { .product(name: "INCITS_4_1986", package: "swift-incits-4-1986") }
    static var standardsTestSupport: Self { .product(name: "StandardsTestSupport", package: "swift-standards") }
}

let package = Package(
    name: "swift-rfc-5322",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(name: .rfc5322, targets: [.rfc5322]),
        .library(name: .rfc5322Foundation, targets: [.rfc5322Foundation]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-rfc-1123.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-standards/swift-standards.git", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-incits-4-1986.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: .rfc5322,
            dependencies: [
                .rfc1123,
                .standards,
                .incits_4_1986
            ]
        ),
        .target(
            name: .rfc5322Foundation,
            dependencies: [
                .rfc5322
            ]
        ),
        .testTarget(
            name: .rfc5322.tests,
            dependencies: [
                .rfc5322,
                .incits_4_1986,
                .standardsTestSupport
            ]
        ),
        .testTarget(
            name: .rfc5322Foundation.tests,
            dependencies: [
                .rfc5322,
                .rfc5322Foundation
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
