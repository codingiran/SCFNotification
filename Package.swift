// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SCFNotification",
    products: [
        .library(
            name: "SCFNotification",
            targets: ["SCFNotification"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SCFNotification",
            dependencies: [],
            path: "Sources",
            resources: [.copy("Resources/PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "SCFNotificationTests",
            dependencies: ["SCFNotification"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
