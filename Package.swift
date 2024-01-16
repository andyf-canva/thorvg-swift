// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "thorvg-swift",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "thorvg-swift",
            targets: ["thorvg-swift"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "thorvg-swift",
            dependencies: ["thorvg"],
            path: "swift",
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .target(
            name: "thorvg",
            path: "src",
            exclude: [
                "bindings/capi/tvgCapi.cpp", // TODO: Source of issue regarding duplicate symbols. Is this ok to remove?
                "examples",
                "bindings/wasm",
                "loaders/external_jpg",
                "loaders/external_png",
                "loaders/external_webp",
                "renderer/gl_engine", // TODO: Do we want a OpenGL engine?
                "renderer/wg_engine", // TODO: Do we want a WebGPU engine?
                "tools",
            ], // TODO: Anything else we want to exclude?
            publicHeadersPath: "bindings/capi",
            cxxSettings: [
                .headerSearchPath("inc"),
                .headerSearchPath("common"),
                .headerSearchPath("bindings"),
                .headerSearchPath("loaders/external_jpg"),
                .headerSearchPath("loaders/jpg"),
                .headerSearchPath("loaders/lottie"),
                .headerSearchPath("loaders/png"),
                .headerSearchPath("loaders/raw"),
                .headerSearchPath("loaders/svg"),
                .headerSearchPath("loaders/ttf"),
                .headerSearchPath("loaders/tvg"),
                .headerSearchPath("renderer"),
                .headerSearchPath("renderer/sw_engine"),
                .headerSearchPath("renderer/gl_engine"),
                .headerSearchPath("savers/gif"),
            ] // TODO: Also need to check other bits.
        ),
        .testTarget(
            name: "thorvg-swift-tests",
            dependencies: ["thorvg-swift"],
            path: "swift-tests",
            resources: [.process("Resources")],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
    ],
    cxxLanguageStandard: .cxx14
)
