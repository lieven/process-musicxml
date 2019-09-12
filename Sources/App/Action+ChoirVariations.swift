//
//  Action+ChoirVariations.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation
import ProcessMusicXML
import ProcessMuseScore

extension Action {
	func performChoirVariationsAction(inputPath: String, outputPath: String?) {
		let inputURL = URL(fileURLWithPath: inputPath)
		
		let outputURL: URL
		if let outputPath = outputPath {
			outputURL = URL(fileURLWithPath: outputPath)
		} else {
			let outputName = inputURL.deletingPathExtension().lastPathComponent.appending("-variations")
			outputURL = inputURL.deletingLastPathComponent()
				.appendingPathComponent(outputName).appendingPathExtension(inputURL.pathExtension)
		}
		
		do {
			if let museScoreFile = try MuseScoreFile(url: inputURL) {
				performChoirVariationsAction(museScore: museScoreFile, outputURL: outputURL)
			} else if let score = try Score(inputFile: inputURL) {
				performChoirVariationsAction(musicXML: score, inputURL: inputURL, outputURL: outputURL)
			} else {
				fputs("Could not parse score\n", stderr)
				exit(1)
			}
		} catch {
			fputs("Could not read score: \(error)\n", stderr)
			exit(1)
		}
	}
	
	private func performChoirVariationsAction(museScore: MuseScoreFile, outputURL: URL) {
		let document = museScore.document
		
		if let soprano = document.choirPart(.soprano), let alto = document.choirPart(.alto) {
			document.extractMezzos(soprano: soprano, alto: alto)
		} else if let women = document.choirPart(.women) {
			document.splitWomen(part: women)
		}
		
		if let tenor = document.choirPart(.tenor), let bass = document.choirPart(.bass) {
			document.extractBaritones(tenor: tenor, bass: bass)
		} else if let men = document.choirPart(.men) {
			document.splitMen(part: men)
		}
		
		do {
			try museScore.export(to: outputURL)
		} catch {
			fputs("Could not write score: \(error)\n", stderr)
			exit(1)
		}
	}
	
	private func performChoirVariationsAction(musicXML: Score, inputURL: URL, outputURL: URL) {
		Score.transform(inputURL: inputURL, outputURL: outputURL) { (score) in
			if let soprano = score.sopranoPart, let alto = score.altoPart {
				score.extractMezzos(soprano: soprano, alto: alto)
			} else if let women = score.womenPart {
				score.splitWomen(part: women)
			}
			if let tenor = score.tenorPart, let bass = score.bassPart {
				score.extractBaritones(tenor: tenor, bass: bass)
			} else if let men = score.menPart {
				score.splitMen(part: men)
			}
		}
	}
}




