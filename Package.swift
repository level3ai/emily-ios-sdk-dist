// swift-tools-version: 5.9
//
// EmilyChat iOS SDK — public Swift Package manifest.
//
// This package ships the SDK as a pre-built XCFramework: `swift-tools-version`
// and the platform floor match what the binary was compiled against.
//
// This file is generated per release; the url/checksum pair is not hand-edited.
//
import PackageDescription

let package = Package(
    name: "EmilyChat",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "EmilyChat",
            targets: ["EmilyChat"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "EmilyChat",
            url: "https://static.lv3.ai/ios/EmilyChat-1.2.1.xcframework.zip",
            checksum: "b85ae30f64313b0978a44f30321bd86feadf7713a5ce0424f403f2c484f24033"
        )
    ]
)
