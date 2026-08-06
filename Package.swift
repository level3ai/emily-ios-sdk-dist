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
            url: "https://static.lv3.ai/ios/EmilyChat-1.2.2.xcframework.zip",
            checksum: "acf61d49934345d4231d1be1028471d3d18ff5159ed70982c35b4676134c849a"
        )
    ]
)
