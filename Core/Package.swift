// swift-tools-version: 6.0
import PackageDescription

// FocusPulseCore — the platform-agnostic Domain layer (entities + domain services).
// Pure Swift (Foundation + Combine) so it compiles and unit-tests on macOS via `swift test`,
// and is consumed by the iOS app target. No UIKit / SwiftUI here.
//
// Targets:
//   FocusPulseCore       — the library the iOS app links against.
//   CoreCheck            — a dependency-free assertion runner so the domain logic can be
//                          verified with just Command Line Tools (`swift run CoreCheck`),
//                          on machines without full Xcode / XCTest.
//   FocusPulseCoreTests  — the real XCTest suite (runs under `swift test` in Xcode / CI).
let package = Package(
    name: "FocusPulseCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "FocusPulseCore", targets: ["FocusPulseCore"])
    ],
    targets: [
        .target(name: "FocusPulseCore"),
        .executableTarget(name: "CoreCheck", dependencies: ["FocusPulseCore"]),
        .testTarget(name: "FocusPulseCoreTests", dependencies: ["FocusPulseCore"])
    ]
)
