// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CaliperUI",
    platforms: [.macOS("26.0"), .iOS("26.0")],
    products: [.library(name: "CaliperUI", targets: ["CaliperUI"])],
    dependencies: [
        .package(path: "../CaliperKernel"),
        .package(path: "../CaliperCore"),
        .package(path: "../CaliperRender"),
    ],
    targets: [
        .target(name: "CaliperUI",
                dependencies: ["CaliperKernel", "CaliperCore", "CaliperRender"],
                swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
