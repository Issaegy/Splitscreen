// swift-tools-version: 5.9

// Dieses Paket ist ein "App Playground": Es lässt sich direkt auf dem iPad
// in der kostenlosen App "Swift Playgrounds" öffnen und starten
// (oder auf dem Mac in Xcode).

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "SplitScreen",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "SplitScreen",
            targets: ["AppModule"],
            bundleIdentifier: "com.example.splitscreen",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .leaf),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
