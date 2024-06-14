// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProcessMusicXML",
    platforms: [
    	.macOS(.v10_12)
    ],
    products: [
		.executable(name: "process_musicxml", targets: ["process_musicxml"]),
    	.library(name: "ProcessMusicXML", type: .static, targets: ["ProcessMusicXML"]),
    	.library(name: "ProcessMuseScore", type: .static, targets: ["ProcessMuseScore"])
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation/", .exact("0.9.9")),
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
            	"ZIPFoundation",
			],
            path: "Sources/ProcessMuseScore"
        ),
        .executableTarget(
            name: "process_musicxml",
            dependencies: [
            	.target(name: "ProcessMusicXML"),
            	.target(name: "ProcessMuseScore")
			],
            path: "Sources/App"
		),
		.testTarget(name: "ProcessMuseScoreTests",
			dependencies: [
				.target(name: "process_musicxml")
			],
			path: "Tests/ProcessMuseScore",
			resources: [
				.copy("MeasureWithPartialVoice.mscx"),
				.copy("Triplet_Test.mscx"),
				.copy("ChapterMarkersTest-norepeats.mscx"),
			]
		)
    ]
)
