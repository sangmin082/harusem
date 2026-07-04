// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HarusemKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "HarusemKit", targets: ["HarusemKit"]),
        .executable(name: "harusem-gen", targets: ["harusem-gen"]),
    ],
    targets: [
        .target(name: "HarusemKit"),
        .executableTarget(name: "harusem-gen", dependencies: ["HarusemKit"]),
        .testTarget(name: "HarusemKitTests", dependencies: ["HarusemKit"]),
    ]
)
