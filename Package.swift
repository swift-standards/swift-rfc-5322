// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let rfc5322: Self = "RFC_5322"
}

extension Target.Dependency {
    static var rfc5322: Self { .target(name: .rfc5322) }
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
        // Add RFC dependencies here as needed
        // .package(url: "https://github.com/swift-web-standards/swift-rfc-1123.git", branch: "main"),
    ],
    targets: [
        .target(
            name: .rfc5322,
            dependencies: [
                // Add target dependencies here
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