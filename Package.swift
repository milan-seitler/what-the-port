// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhatThePort",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "WhatThePort", targets: ["WhatThePort"])
    ],
    targets: [
        .executableTarget(
            name: "WhatThePort",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
