// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ServerBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ServerBar", targets: ["ServerBar"])
    ],
    targets: [
        .executableTarget(
            name: "ServerBar",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
