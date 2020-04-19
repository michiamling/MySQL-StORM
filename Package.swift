// swift-tools-version:5.2

// Generated automatically by Perfect Assistant Application
// Date: 2017-01-12 22:15:25 +0000

import PackageDescription
let package = Package(
    name: "MySQLStORM",
    products: [.library(name: "MySQLStORM", targets: ["MySQLStORM"])],
    dependencies: [
        .package(url: "https://github.com/michiamling/Perfect-MySQL.git", from: "2.0.0"),
        .package(url: "https://github.com/SwiftORM/StORM.git", from: "3.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-Logger.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "MySQLStORM", dependencies: ["Perfect-MySQL", "StORM", "Perfect-Logger"])
    ]
)
