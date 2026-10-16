// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PixiePopMac",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "PixiePopMac", targets: ["PixiePopMac"])],
    targets: [
        .executableTarget(name: "PixiePopMac", path: "Sources"),
        .testTarget(name: "PixiePopMacTests", dependencies: ["PixiePopMac"], path: "Tests")
    ]
)
