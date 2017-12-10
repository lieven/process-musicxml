//
//  Action+SATB.swift
//  ExplodeVoices
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation

extension Action {
	func performSATBAction(args: SATBArgs) {
		Score.transform(inputURL: args.inputURL, outputURL: args.outputURL) { (score) in
			if let soprano = score.sopranoPart, let alto = score.altoPart {
				score.extractMezzos(soprano: soprano, alto: alto)
			}
			if let tenor = score.tenorPart, let bass = score.bassPart {
				score.extractBaritones(tenor: tenor, bass: bass)
			}
		}
	}
}


struct SATBArgs {
	let inputURL: URL
	let outputURL: URL
	
	init?(args: [String]) {
		guard let inputPath = args[safe: 0] else {
			return nil
		}
		
		inputURL = URL(fileURLWithPath: inputPath)
		
		if let outputPath = args[safe: 1] {
			outputURL = URL(fileURLWithPath: outputPath)
		} else {
			outputURL = SATBArgs.outputURL(inputURL: inputURL)
		}
	}
	
	static let usage = "<inputPath> <outputPath>?"
	
	static func outputURL(inputURL: URL) -> URL {
		let outputName = inputURL.deletingPathExtension().lastPathComponent.appending("-SMATBB")
		return inputURL.deletingLastPathComponent().appendingPathComponent(outputName).appendingPathExtension(inputURL.pathExtension)
	}
}




