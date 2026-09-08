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
            url: "https://static.lv3.ai/ios/EmilyChat-2.2.0.xcframework.zip",
            checksum: "bd8106343998bc53a55b84b0ce2b2dcf05388fca39ee9329e2fff6e0f06fba84"
        )
    ]
)
