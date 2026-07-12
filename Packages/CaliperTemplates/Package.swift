// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CaliperTemplates",
    platforms: [.macOS("26.0"), .iOS("26.0")],
    products: [.library(name: "CaliperTemplates", targets: ["CaliperTemplates"])],
    dependencies: [.package(path: "../CaliperKernel"), .package(path: "../CaliperCore")],
    targets: [
        .target(name: "CaliperTemplates", dependencies: ["CaliperKernel", "CaliperCore"],
                swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
