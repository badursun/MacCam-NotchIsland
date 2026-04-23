// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacCam",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MacCam",
            path: "Sources/MacCam"
        )
    ]
)
