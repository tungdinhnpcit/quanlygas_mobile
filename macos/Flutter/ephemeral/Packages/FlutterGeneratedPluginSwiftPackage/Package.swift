// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "connectivity_plus", path: "../.packages/connectivity_plus-6.1.5"),
        .package(name: "file_selector_macos", path: "../.packages/file_selector_macos-0.9.5"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-3.15.2"),
        .package(name: "firebase_messaging", path: "../.packages/firebase_messaging-15.2.10"),
        .package(name: "geolocator_apple", path: "../.packages/geolocator_apple-2.3.13"),
        .package(name: "local_auth_darwin", path: "../.packages/local_auth_darwin-1.6.1"),
        .package(name: "path_provider_foundation", path: "../.packages/path_provider_foundation-2.5.1"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.6"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin-2.4.2"),
        .package(name: "url_launcher_macos", path: "../.packages/url_launcher_macos-3.2.5"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "connectivity-plus", package: "connectivity_plus"),
                .product(name: "file-selector-macos", package: "file_selector_macos"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-messaging", package: "firebase_messaging"),
                .product(name: "geolocator-apple", package: "geolocator_apple"),
                .product(name: "local-auth-darwin", package: "local_auth_darwin"),
                .product(name: "path-provider-foundation", package: "path_provider_foundation"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "url-launcher-macos", package: "url_launcher_macos"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
