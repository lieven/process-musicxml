//
//  Action+ChoirVariations.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation

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
	
		Score.transform(inputURL: inputURL, outputURL: outputURL) { (score) in
			if let soprano = score.sopranoPart, let alto = score.altoPart {
				score.extractMezzos(soprano: soprano, alto: alto)
			}
			if let tenor = score.tenorPart, let bass = score.bassPart {
				score.extractBaritones(tenor: tenor, bass: bass)
			}
		}
	}
}




