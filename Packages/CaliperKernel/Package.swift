// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CaliperKernel",
    platforms: [.macOS("26.0"), .iOS("26.0")],
    products: [
        .library(name: "CaliperKernel", targets: ["CaliperKernel"]),
    ],
    targets: [
        // Pure-Swift abstraction. MUST NOT depend on OCCT, Parasolid, or any
        // concrete geometry engine. This is the seam that makes the kernel swappable.
        .target(
            name: "CaliperKernel",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "CaliperKernelTests",
            dependencies: ["CaliperKernel"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
