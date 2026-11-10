// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LuminaClean",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "LuminaClean"
        )
    ]
)
