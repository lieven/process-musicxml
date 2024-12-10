//
//  ChapterMarkersTests.swift
//  
//
//  Created by Lieven Dekeyser on 14/06/2024.
//

import XCTest
@testable import ProcessMuseScore


final class ChapterMarkersTests: XCTestCase {

	private let accuracy = 0.01
	
	private func testChapterMarkers(fileName: String) throws -> [ChapterMarker] {
		let inputURL = try XCTUnwrap(Bundle.module.resourceURL?.appendingPathComponent(fileName), "Test file \(fileName) not found")
		
		let musescore = try XCTUnwrap(MuseScoreFile(url: inputURL), "Could not read test file \(inputURL.lastPathComponent)")
		
		let chapterMarkers = try XCTUnwrap(musescore.document.chapterMarkers, "Expected chapter markers")
		
		return chapterMarkers
	}
	
	func testBreathsAndFermatas() throws {
		let chapterMarkers = try testChapterMarkers(fileName: "ChapterMarkersTest-norepeats.mscx")
		
		XCTAssertEqual(chapterMarkers.count, 3)
		
		let chapterMarkerA = chapterMarkers[0]
		let chapterMarkerB = chapterMarkers[1]
		let chapterMarkerC = chapterMarkers[2]
		
		XCTAssertEqual(chapterMarkerA.mark, "A")
		XCTAssertEqual(chapterMarkerA.time, 2.0)
		
		// Breath
		XCTAssertEqual(chapterMarkerB.mark, "B")
		XCTAssertEqual(chapterMarkerB.time, 9.5, accuracy: accuracy)
		
		// Fermata
		XCTAssertEqual(chapterMarkerC.mark, "C")
		XCTAssertEqual(chapterMarkerC.time, 11.75, accuracy: accuracy)
	}
	
	func testRepeats() throws {
		
		let chapterMarkers = try testChapterMarkers(fileName: "ChapterMarkersTest-with-repeats.mscx")
		/*
			2
		A
			3
			3
			3.5
		A
			3
			3
			3.5
		A
			3
			3
			3.5
		B
			2.25
		C
		*/
		
		let expectedChapterMarkers: [ChapterMarker] = [
			.init(mark: "A", time: 2.0),
			.init(mark: "A", time: 11.5),
			.init(mark: "A", time: 21.0),
			.init(mark: "B", time: 30.5),
			.init(mark: "C", time: 32.75),
		]
		
		XCTAssertEqual(chapterMarkers.count, expectedChapterMarkers.count)
		
		let n = min(chapterMarkers.count, expectedChapterMarkers.count)
		
		for i in 0..<n {
			let found = chapterMarkers[i]
			let expected = expectedChapterMarkers[i]
			
			XCTAssertEqual(found.mark, expected.mark, "markers[\(i)]")
			XCTAssertEqual(found.time, expected.time, accuracy: accuracy, "markers[\(i)]")
		}
	}
	
	func testTempoChanges() throws {
		let chapterMarkers = try testChapterMarkers(fileName: "ChapterMarkersTest-tempo-changes.mscx")
		
		guard chapterMarkers.count == 3 else {
			XCTFail("Expected 3 chapter markers")
			return
		}
		
		//     0s:     1/4 at 60bpm (1s)
		// [A] 1s:     1/4 at 80bpm (0.75s)
		//     1.75s:  1/4 at 120bpm (0.5s)
		//     2.25s:  1/4 at 60bpm (1s)
		// -----------------------------------
		// [B] 3.25s:  1.5/4 at 90bpm (1s)
		//     4.25s:  1.5/4 at 135bpm (0.66s)
		// [C] 4.91s:  1/4 at 120bpm (0.5s)
		// -----------------------------------
		//     Total: 5.41s
		
		
		
		let chapterMarkerA = chapterMarkers[0]
		let chapterMarkerB = chapterMarkers[1]
		let chapterMarkerC = chapterMarkers[2]
		
		XCTAssertEqual(chapterMarkerA.mark, "A")
		XCTAssertEqual(chapterMarkerA.time, 1.0)
		
		XCTAssertEqual(chapterMarkerB.mark, "B")
		XCTAssertEqual(chapterMarkerB.time, 3.25, accuracy: accuracy)
		
		XCTAssertEqual(chapterMarkerC.mark, "C")
		XCTAssertEqual(chapterMarkerC.time, 4.9166, accuracy: accuracy)
	}
}
