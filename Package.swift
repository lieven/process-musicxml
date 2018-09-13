// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProcessMusicXML",
    products: [
    	.library(name: "ProcessMusicXML", targets: ["ProcessMusicXML"]),
    	.executable(name: "process_musicxml", targets: ["process_musicxml"])
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation/", .upToNextMajor(from: "0.9.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
        	name: "ProcessMusicXML",
            dependencies: ["ZIPFoundation"],
            path: "Sources/Library"
        ),
        .target(
            name: "process_musicxml",
            dependencies: [.target(name: "ProcessMusicXML")],
            path: "Sources/App"
		),
    ]
)
