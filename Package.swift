// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyESCPOS",
    products: [
        .library(
            name: "SwiftyESCPOS",
            targets: ["SwiftyESCPOS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket.git", from: "7.6.4"),
    ],
    targets: [
        .target(
            name: "SwiftyESCPOS",
            dependencies: ["CocoaAsyncSocket"]),
    ]
)
