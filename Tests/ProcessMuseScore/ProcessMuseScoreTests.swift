//
//  File.swift
//  
//
//  Created by Lieven Dekeyser on 21/11/2021.
//

import XCTest
@testable import ProcessMuseScore
@testable import process_musicxml

class ProcessMuseScoreTests: XCTestCase {
	
	let outputPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("ProcessMuseScoreTests.mscx")
	
	override func setUp() {
		super.setUp()
	}
	
	func testMeasureWithPartialVoice() throws {
		let musescore = try testExtractChoirVariations(name: "MeasureWithPartialVoice")
		
		XCTAssertEqual(musescore.document.parts.count, 3)
	}
	
	func testTriplets() throws {
		_ = try testExtractChoirVariations(name: "Triplet_Test")
	}
	
	func testExtractChoirVariations(name: String, pathExtension: String = "mscx") throws -> MuseScoreFile {
		guard let inputURL = Bundle.module.url(forResource: name, withExtension: pathExtension) else {
			XCTFail("Test file \(name).\(pathExtension) not found")
			exit(1)
		}
		
		guard let musescore = try? MuseScoreFile(url: inputURL) else {
			XCTFail("Could not read test file \(name).\(pathExtension)")
			exit(1)
		}
		
		musescore.document.extractChoirVariations()
		
		try musescore.export(to: URL(fileURLWithPath: outputPath))
		
		print("written to \(outputPath)")
		
		return musescore
	}
	
	func testChapterMarkers() throws {
		let inputURL = try XCTUnwrap(Bundle.module.url(forResource: "ChapterMarkersTest-norepeats", withExtension: "mscx"), "Test file ChapterMarkersTest-norepeats.mscx not found")
		
		let musescore = try XCTUnwrap(MuseScoreFile(url: inputURL), "Could not read test file \(inputURL.lastPathComponent)")
		
		let chapterMarkers = try XCTUnwrap(musescore.document.chapterMarkers, "Expected chapter markers")
		
		XCTAssertEqual(chapterMarkers.count, 3)
		
		let chapterMarkerA = chapterMarkers[0]
		let chapterMarkerB = chapterMarkers[1]
		let chapterMarkerC = chapterMarkers[2]
		
		XCTAssertEqual(chapterMarkerA.mark, "A")
		XCTAssertEqual(chapterMarkerA.time, 2.0)
		
		XCTAssertEqual(chapterMarkerB.mark, "B")
		XCTAssertEqual(chapterMarkerB.time, 9.5, accuracy: 0.01)
		
		XCTAssertEqual(chapterMarkerC.mark, "C")
		XCTAssertEqual(chapterMarkerC.time, 11.75, accuracy: 0.01)
	}
}
