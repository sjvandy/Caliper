// swift-tools-version: 6.2
import PackageDescription

// The ONLY package permitted to link OpenCASCADE. Structure:
//
//   CaliperOCCTFacade  (ObjC++/C target)  → wraps OCCT's C++ API, exposes a flat C interface
//   CaliperKernelBridge (Swift target)    → conforms to GeometryKernel, calls the facade
//
// OCCT itself arrives as a prebuilt binaryTarget (.xcframework) placed in
// ../../Vendor/OCCT/OCCT.xcframework. Until that exists, the facade is a stub that
// reports "not implemented", so the whole workspace still compiles and the app runs
// on MockKernel. Un-comment the binaryTarget + linkedLibrary lines when OCCT is ready.

let package = Package(
    name: "CaliperKernelBridge",
    platforms: [.macOS("26.0"), .iOS("26.0")],
    products: [
        .library(name: "CaliperKernelBridge", targets: ["CaliperKernelBridge"]),
    ],
    dependencies: [
        .package(path: "../CaliperKernel"),
    ],
    targets: [
        // .binaryTarget(name: "OCCT", path: "../../Vendor/OCCT/OCCT.xcframework"),

        .target(
            name: "CaliperOCCTFacade",
            // dependencies: ["OCCT"],
            publicHeadersPath: "include"
            // cxxSettings: [.headerSearchPath("../../../Vendor/OCCT/OCCT.xcframework/Headers")]
        ),
        .target(
            name: "CaliperKernelBridge",
            dependencies: ["CaliperKernel", "CaliperOCCTFacade"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                // OCCT interop goes through the flat C facade, so C++ interop is
                // not required here; the facade absorbs all C++ contact.
            ]
        ),
    ]
)
