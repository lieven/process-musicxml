//
//  Action+ChapterMarkers.swift
//
//
//  Created by Lieven Dekeyser on 23/05/2024.
//

import Foundation
import ProcessMuseScore


extension Action {
	func performChapterMarkers(inputPath: String, outputPath: String?) {
		let inputURL = URL(fileURLWithPath: inputPath)
		
		let outputURL: URL
		if let outputPath = outputPath {
			outputURL = URL(fileURLWithPath: outputPath)
		} else {
			let outputName = inputURL.deletingPathExtension().lastPathComponent.appending("-chapters")
			outputURL = inputURL.deletingLastPathComponent()
				.appendingPathComponent(outputName).appendingPathExtension("json")
		}
		
		do {
			if let museScoreFile = try MuseScoreFile(url: inputURL) {
				performChapterMarkersAction(museScore: museScoreFile, outputURL: outputURL)
			} else {
				fputs("Could not parse score\n", stderr)
				exit(1)
			}
		} catch {
			fputs("Could not read score: \(error)\n", stderr)
			exit(1)
		}
	}
	
	func performChapterMarkersAction(museScore: MuseScoreFile, outputURL: URL) {
		guard let chapterMarkers = museScore.document.chapterMarkers else {
			fputs("Could not find first chapter markers\n", stderr)
			exit(1)
		}
		
		let chapterMarkerDicts = chapterMarkers.map {
			return [
				"mark": $0.mark,
				"time": $0.time
			]
		}
		
		do {
			let data = try JSONSerialization.data(withJSONObject: chapterMarkerDicts, options: [.prettyPrinted])
			
			try data.write(to: outputURL)
		} catch {
			fputs("Error outputting chapter markers: \(error)\n", stderr)
			exit(1)
		}
		
	}
}
