// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let remoteSocketxPackageUrl = "https://github.com/Eclypses/mte-socketx-client-ios.git"
let remoteSocketxPackageVersion = "2.2.0"

func packageDirectory() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .resolvingSymlinksInPath()
}

func readLocalProperty(_ key: String) -> String? {
    let fileManager = FileManager.default
    let searchPaths = [
        packageDirectory().appendingPathComponent("local.properties"),
        packageDirectory().deletingLastPathComponent().appendingPathComponent("local.properties"),
        packageDirectory().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("local.properties")
    ]

    for path in searchPaths where fileManager.fileExists(atPath: path.path) {
        guard let contents = try? String(contentsOf: path, encoding: .utf8) else {
            continue
        }

        for rawLine in contents.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") {
                continue
            }

            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 && parts[0].trimmingCharacters(in: .whitespaces) == key {
                let value = parts[1]
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                return value.isEmpty ? nil : value
            }
        }
    }

    return nil
}

let localSocketxPath = ProcessInfo.processInfo.environment["MTE_SOCKETX_IOS_PATH"]
    ?? readLocalProperty("mteSocketxIosPath")

let socketxPackageDependency: Package.Dependency
let socketxTargetDependency: Target.Dependency

if let localSocketxPath, !localSocketxPath.isEmpty {
    socketxPackageDependency = .package(path: localSocketxPath)
    socketxTargetDependency = .product(name: "SocketXClient", package: "mte-socketx-client-ios")
} else {
    socketxPackageDependency = .package(url: remoteSocketxPackageUrl, .upToNextMajor(from: Version(stringLiteral: remoteSocketxPackageVersion)))
    socketxTargetDependency = .product(name: "SocketXClient", package: "mte-socketx-client-ios")
}

let package = Package(
    name: "socketx_client",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .library(name: "socketx-client",
                 targets: ["socketx_client"])
    ],
    dependencies: [
        socketxPackageDependency
    ],
    targets: [
        .target(
            name: "socketx_client",
            dependencies: [
                socketxTargetDependency
            ],
            resources: [
                // If your plugin requires a privacy manifest, for example if it uses any required
                // reason APIs, update the PrivacyInfo.xcprivacy file to describe your plugin's
                // privacy impact, and then uncomment these lines. For more information, see
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                // .process("PrivacyInfo.xcprivacy"),

                // If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ]
        )
    ]
)
