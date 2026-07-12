// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CaliperRender",
    platforms: [.macOS("26.0"), .iOS("26.0")],
    products: [.library(name: "CaliperRender", targets: ["CaliperRender"])],
    dependencies: [.package(path: "../CaliperKernel")],
    targets: [
        .target(name: "CaliperRender", dependencies: ["CaliperKernel"],
                swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
