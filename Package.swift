// swift-tools-version: 6.2

import PackageDescription

extension String {
    static let rfc5322: Self = "RFC 5322"
    static let rfc5322Foundation: Self = "RFC 5322 Foundation"
}

extension Target.Dependency {
    static var rfc5322: Self { .target(name: .rfc5322) }
    static var rfc5322Foundation: Self { .target(name: .rfc5322Foundation) }
    static var rfc1123: Self { .product(name: "RFC 1123", package: "swift-rfc-1123") }
    static var standards: Self { .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions") }
    static var binary: Self { .product(name: "Binary Primitives", package: "swift-binary-primitives") }
    static var time: Self { .product(name: "Time Primitives", package: "swift-time-primitives") }
    static var incits_4_1986: Self {
        .product(name: "INCITS 4 1986", package: "swift-incits-4-1986")
    }
    static var standardsTestSupport: Self {
        .product(name: "Test Primitives", package: "swift-test-primitives")
    }
}

let package = Package(
    name: "swift-rfc-5322",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(name: .rfc5322, targets: [.rfc5322]),
        .library(name: .rfc5322Foundation, targets: [.rfc5322Foundation]),
    ],
    dependencies: [
        .package(path: "../swift-rfc-1123"),
        .package(path: "../../swift-primitives/swift-standard-library-extensions"),
        .package(path: "../../swift-primitives/swift-binary-primitives"),
        .package(path: "../../swift-primitives/swift-time-primitives"),
        .package(path: "../../swift-primitives/swift-test-primitives"),
        .package(path: "../swift-incits-4-1986"),
    ],
    targets: [
        .target(
            name: .rfc5322,
            dependencies: [
                .standards,
                .binary,
                .time,
                .rfc1123,
                .incits_4_1986,
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
                .time,
                .incits_4_1986,
                .standardsTestSupport,
            ]
        ),
        .testTarget(
            name: .rfc5322Foundation.tests,
            dependencies: [
                .rfc5322,
                .rfc5322Foundation,
                .time,
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings =
        existing + [
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
        ]
}
