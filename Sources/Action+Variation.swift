//
//  Action+Variation.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation

extension Action {
	func performVariationAction(args: VariationArgs) {
		Score.transform(inputURL: args.inputURL, outputURL: args.outputURL) { (score) in
			score.extractVariation(
				basePartID: args.basePartID, baseVoice: args.baseVoice,
				variationPartID: args.variationPartID, variationVoice: args.variationVoice, cut: true,
				destinationPartName: args.newPartName
			)
		}
	}
}

struct VariationArgs {
	let inputURL: URL
	let basePartID: String
	let baseVoice: String
	let variationPartID: String
	let variationVoice: String
	let newPartName: String
	let outputURL: URL
	
	init(inputURL: URL, basePartID: String, baseVoice: String, variationPartID: String, variationVoice: String, newPartName: String, outputURL: URL) {
		self.inputURL = inputURL
		self.basePartID = basePartID
		self.baseVoice = baseVoice
		self.variationPartID = variationPartID
		self.variationVoice = variationVoice
		self.newPartName = newPartName
		self.outputURL = outputURL
	}
	
	init?(args: [String]) {
		guard
			let inputPath = args[safe: .inputPath],
			let basePartID = args[safe: .basePartID],
			let baseVoice = args[safe: .baseVoice],
			let variationPartID = args[safe: .variationPartID],
			let variationVoice = args[safe: .variationVoice],
			let newPartName = args[safe: .newPartName]
		else {
			return nil
		}
		
		let inputURL = URL(fileURLWithPath: inputPath)
		let outputURL: URL
		if let outputPath = args[safe: .outputPath] {
			outputURL = URL(fileURLWithPath: outputPath)
		} else {
			outputURL = VariationArgs.outputURL(inputURL: inputURL)
		}
		
		self.init(inputURL: inputURL, basePartID: basePartID, baseVoice: baseVoice, variationPartID: variationPartID, variationVoice: variationVoice, newPartName: newPartName, outputURL: outputURL)
	}
	
	static let verb = "variation"
	static let usage = "<inputPath> <basePartID> <baseVoice> <variationPartID> <variationVoice> <newPartName> <outputPath>?"
	
	static func outputURL(inputURL: URL) -> URL {
		let outputName = inputURL.deletingPathExtension().lastPathComponent.appending("-variation.").appending(inputURL.pathExtension)
		return inputURL.deletingLastPathComponent().appendingPathComponent(outputName)
	}
}


fileprivate enum VariationArgIndex: Int {
	case inputPath = 0
	case basePartID
	case baseVoice
	case variationPartID
	case variationVoice
	case newPartName
	case outputPath
}

fileprivate extension Array {
	subscript (safe index: VariationArgIndex) -> Iterator.Element? {
		return self[safe: index.rawValue]
	}
}
