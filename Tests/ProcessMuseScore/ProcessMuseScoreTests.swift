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
		guard let inputURL = Bundle.module.url(forResource: "MeasureWithPartialVoice", withExtension: "mscx") else {
			XCTFail("Test file not found")
			return
		}
		
		guard let musescore = try? MuseScoreFile(url: inputURL) else {
			XCTFail("Could not read test file")
			return
		}
		
		musescore.document.extractChoirVariations()
		
		let tempFolder = NSTemporaryDirectory() as NSString
		let outputFile = tempFolder.appendingPathComponent("test.mscx")
		
		
		try musescore.export(to: URL(fileURLWithPath: outputFile))
		
		print("written to \(outputFile)")
		
		
		XCTAssertEqual(musescore.document.parts.count, 4)
		
	}
}
