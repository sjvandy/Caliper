// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CaliperCore",
    platforms: [.macOS("26.0"), .iOS("26.0")],
    products: [.library(name: "CaliperCore", targets: ["CaliperCore"])],
    dependencies: [.package(path: "../CaliperKernel")],
    targets: [
        .target(name: "CaliperCore", dependencies: ["CaliperKernel"],
                swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "CaliperCoreTests",
                    dependencies: ["CaliperCore", "CaliperKernel"],
                    swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
