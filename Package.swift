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
            url: "https://static.lv3.ai/ios/EmilyChat-2.0.0.xcframework.zip",
            checksum: "60256cfd41d40132437634e5744fd87829c32c5aa5abee04ba33934420c79792"
        )
    ]
)
