// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DeskPet",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "DeskPet", targets: ["DeskPetApp"]),
        .executable(name: "DeskPetTests", targets: ["DeskPetTests"]),
        .library(name: "DeskPetCore", targets: ["DeskPetCore"])
    ],
    targets: [
        .target(
            name: "DeskPetCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "DeskPetApp",
            dependencies: ["DeskPetCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // Xcode 없이도 테스트를 돌릴 수 있게 만든 작은 러너
        .target(
            name: "TinyTest",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "DeskPetTests",
            dependencies: ["DeskPetCore", "TinyTest"],
            path: "Tests/DeskPetCoreTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
