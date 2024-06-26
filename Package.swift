// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "thorvg-swift",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "thorvg-swift",
            targets: ["thorvg-swift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", .upToNextMinor(from: "1.15.0")),
    ],
    targets: [
        .target(
            name: "thorvg-swift",
            dependencies: ["thorvg"],
            path: "swift"
        ),
        .target(
            name: "thorvg",
            path: "src",
            exclude: [
                "examples",
                "bindings/wasm",
                "loaders/external_jpg",
                "loaders/external_png",
                "loaders/external_webp",
                "renderer/gl_engine",
                "renderer/wg_engine",
                "tools",
            ],
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
            ]
        ),
        .testTarget(
            name: "thorvg-swift-tests",
            dependencies: [
                "thorvg-swift",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "swift-tests",
            exclude: ["SnapshotTests/__Snapshots__"],
            resources: [.process("Resources")]
        ),
    ],
    cxxLanguageStandard: .cxx14
)
