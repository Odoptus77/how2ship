// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PaketlotseCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PaketlotseCore", targets: ["PaketlotseCore"]),
    ],
    targets: [
        .target(
            name: "PaketlotseCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PaketlotseCoreTests",
            dependencies: ["PaketlotseCore"]
        ),
    ]
)
