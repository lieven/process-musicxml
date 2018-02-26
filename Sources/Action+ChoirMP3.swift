//
//  Action+ChoirMP3.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation

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


extension Action {
	func performChoirMP3Action(inputPath: String, outputPath: String?) {
		do {
			let inputFile = URL(fileURLWithPath: inputPath)
			guard let score = try Score(inputFile: inputFile) else {
				fputs("Could not parse score\n", stderr)
				exit(1)
			}
			
			let choirPartNames = [
				"sopraan", "soprano",
				"mezzo-sopraan", "mezzo-soprano",
				"mezzo",
				"vrouwen", "women",
				"mezzo-alt", "mezzo-alto",
				"alt", "alto",
				"tenor",
				"bari-tenor",
				"bariton", "mannen", "men",
				"bari-bas",
				"bas", "bass"
			]
			
			
			let outputFile: URL
			if let outputPath = outputPath {
				outputFile = URL(fileURLWithPath: outputPath)
			} else {
				outputFile = inputFile
			}
			
			score.partList.forEach { (item) in
				if case .part(let part) = item, choirPartNames.contains(part.metadata.name.lowercased()) {
					let outputMP3Name = outputFile.deletingPathExtension().lastPathComponent.appending("-").appending(part.metadata.name)
					let outputMP3URL = outputFile.deletingLastPathComponent().appendingPathComponent(outputMP3Name).appendingPathExtension("mp3")
					score.export(choirPart: part, outputFile: outputMP3URL)
				}
			}
			
		} catch {
			fputs("Could not read XML document: \(error)\n", stderr)
			exit(1)
		}
		
		
	}
}
