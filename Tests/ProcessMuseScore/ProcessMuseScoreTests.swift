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
}
