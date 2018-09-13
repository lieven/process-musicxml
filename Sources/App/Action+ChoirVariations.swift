//
//  Action+ChoirVariations.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation
import ProcessMusicXML

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




