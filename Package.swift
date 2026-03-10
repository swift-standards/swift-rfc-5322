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
        .product(name: "ASCII", package: "swift-ascii")
    }
}

let package = Package(
    name: "swift-rfc-5322",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(name: "RFC 5322", targets: ["RFC 5322"]),
        .library(name: "RFC 5322 Foundation", targets: ["RFC 5322 Foundation"])
    ],
    dependencies: [
        .package(path: "../swift-rfc-1123"),
        .package(path: "../../swift-primitives/swift-standard-library-extensions"),
        .package(path: "../../swift-primitives/swift-binary-primitives"),
        .package(path: "../../swift-primitives/swift-time-primitives"),
        .package(path: "../../swift-foundations/swift-ascii"),
        .package(path: "../../swift-primitives/swift-parser-primitives")
    ],
    targets: [
        .target(
            name: "RFC 5322",
            dependencies: [
                .standards,
                .binary,
                .time,
                .rfc1123,
                .incits_4_1986,
                .product(name: "Parser Primitives", package: "swift-parser-primitives")
            ]
        ),
        .target(
            name: "RFC 5322 Foundation",
            dependencies: [
                .rfc5322
            ]
        ),
        .testTarget(
            name: "RFC 5322 Foundation Tests",
            dependencies: [
                "RFC 5322",
                "RFC 5322 Foundation",
            ]
        ),
        .testTarget(
            name: "RFC 5322 Tests",
            dependencies: [
                "RFC 5322",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
