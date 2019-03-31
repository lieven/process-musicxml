//
//  Action+ChoirMP3.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation
import ProcessMusicXML
import ProcessMuseScore


fileprivate extension Score {
	func export(choirPart: Part, outputFile: URL) {
		partList.forEach { (item) in
			if case .part(let part) = item {
				part.metadata.volume = part.metadata.identifier == choirPart.metadata.identifier ? "100.0" : "33.0"
				part.reduceDynamics()
			}
		}
		
		export(outputFile: outputFile)
	}
}

fileprivate extension MuseScoreFile {
	func export(choirPart: MuseScorePart, outputFile: URL) throws {
		let currentPartName = choirPart.name
		document.parts.forEach { (part) in
			part.volume = part.name == currentPartName ? 1.0 : 0.33
		}
		
		try save(to: outputFile)
	}
}


extension Action {
	fileprivate static let choirPartNames = [
		"sopraan", "soprano",
		"mezzo-sopraan", "mezzo-soprano",
		"mezzo",
		"vrouwen", "women", "sopraan/alt",
		"mezzo-alt", "mezzo-alto",
		"alt", "alto",
		"tenor",
		"bari-tenor",
		"bariton", "mannen", "men", "tenor/bas",
		"bari-bas",
		"bas", "bass",
		"sopraan/tenor", "soprano/tenor",
		"alt/bas", "alto/bass"
	]
	
	func performChoirMP3Action(inputPath: String, outputPath: String?) {
		do {
			let inputFile = URL(fileURLWithPath: inputPath)
			
			let outputFile: URL
			if let outputPath = outputPath {
				outputFile = URL(fileURLWithPath: outputPath)
			} else {
				outputFile = inputFile
			}
			
			
			if let museScoreFile = try MuseScoreFile(url: inputFile) {
				performChoirMP3Action(museScore: museScoreFile, outputFile: outputFile)
			} else if let score = try Score(inputFile: inputFile) {
				performChoirMP3Action(musicXML: score, inputFile: inputFile, outputFile: outputFile)
			} else {
				fputs("Could not parse score\n", stderr)
				exit(1)
			}
		} catch {
			fputs("Could not read score: \(error)\n", stderr)
			exit(1)
		}
	}
	
	func performChoirMP3Action(museScore file: MuseScoreFile, outputFile: URL) {
		let document = file.document
		document.reduceDynamics()
		document.parts.forEach { (part) in
			if let partName = part.name, Action.choirPartNames.contains(partName.lowercased()) {
				let outputMP3URL = outputFile.mp3URL(partName: partName)
				let tempFile = outputMP3URL.appendingPathExtension("mscx")
				
				do {
					try file.export(choirPart: part, outputFile: tempFile)
					try MuseScore.convert(inputFile: tempFile, outputFile: outputMP3URL)
					try FileManager.default.removeItem(at: tempFile)
				} catch {
					fputs("Could not export part \(partName): \(error.localizedDescription)\n", stderr)
				}
			}
		}
	}
	
	func performChoirMP3Action(musicXML score: Score, inputFile: URL, outputFile: URL) {
		score.partList.forEach { (item) in
			if case .part(let part) = item, Action.choirPartNames.contains(part.metadata.name.lowercased()) {
				let outputMP3URL = outputFile.mp3URL(partName: part.metadata.name)
				score.export(choirPart: part, outputFile: outputMP3URL)
			}
		}
	}
}

extension URL {
	fileprivate func mp3URL(partName: String) -> URL {
		let outputMP3Name = self.deletingPathExtension().lastPathComponent.appending("-").appending(partName.replacingOccurrences(of: "/", with: "-"))
		let outputMP3URL = self.deletingLastPathComponent().appendingPathComponent(outputMP3Name).appendingPathExtension("mp3")
		return outputMP3URL
	}
}
