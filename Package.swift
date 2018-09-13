// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProcessMusicXML",
    products: [
    	.library(name: "ProcessMusicXML", targets: ["ProcessMusicXML"]),
    	.library(name: "ProcessMuseScore", targets: ["ProcessMuseScore"]),
    	.executable(name: "process_musicxml", targets: ["process_musicxml"])
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation/", .upToNextMajor(from: "0.9.0"))
    ],
    targets: [
        .target(
        	name: "ProcessMusicXML",
            path: "Sources/Library"
        ),
        .target(
        	name: "ProcessMuseScore",
            dependencies: [
            	.target(name: "ProcessMusicXML"),
            	"ZIPFoundation"
			],
            path: "Sources/ProcessMuseScore"
        ),
        .target(
            name: "process_musicxml",
            dependencies: [
            	.target(name: "ProcessMusicXML"),
            	.target(name: "ProcessMuseScore")
			],
            path: "Sources/App"
		),
    ]
)
