// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VokabelKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "VokabelKit", targets: ["VokabelKit"])],
    targets: [
        .target(name: "VokabelKit"),
        .testTarget(name: "VokabelKitTests", dependencies: ["VokabelKit"]),
    ]
)
