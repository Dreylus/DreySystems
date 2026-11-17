// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "FactoryCore", platforms: [.macOS(.v13), .iOS(.v17)],
    products: [.library(name: "FactoryCore", targets: ["FactoryCore"])],
    targets: [.target(name: "FactoryCore", path: "Shared/Core"),
              .testTarget(name: "FactoryCoreTests", dependencies: ["FactoryCore"], path: "Tests")])
