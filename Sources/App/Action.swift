//
//  Action.swift
//  ProcessMusicXML
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation


enum Action {
	case variation(args: VariationArgs?)
	case choirVariations(inputPath: String?, outputPath: String?)
	case choirMP3(inputPath: String?, outputPath: String?)
	case extractRange(inputPath: String?, outputPath: String?, firstMeasure: Int, lastMeasure: Int)
	
	static let all: [Action] = [
		.variation(args: nil),
		.choirVariations(inputPath: nil, outputPath: nil),
		.choirMP3(inputPath: nil, outputPath: nil),
		.extractRange(inputPath: nil, outputPath: nil, firstMeasure: 1, lastMeasure: 1)
	]
	
	init?(args: [String]) {
		guard let verb = args[safe: 1] else {
			return nil
		}
		
		switch verb {
		case "variation":
			self = .variation(args: VariationArgs(args: Array(args[2...])))
		case "choirVariations":
			self = .choirVariations(inputPath: args[safe: 2], outputPath: args[safe: 3])
		case "choirMP3":
			self = .choirMP3(inputPath: args[safe: 2], outputPath: args[safe: 3])
		case "extractRange":
			guard
				let firstMeasureString = args[safe: 4], let lastMeasureString = args[safe: 5],
				let firstMeasure = Int(firstMeasureString), let lastMeasure = Int(lastMeasureString),
				firstMeasure > 0, lastMeasure >= firstMeasure
			else {
				return nil
			}
			self = .extractRange(inputPath: args[safe: 2], outputPath: args[safe: 3], firstMeasure: firstMeasure, lastMeasure: lastMeasure)
		default:
			return nil
		}
		
	}
	
	var verb: String {
		switch self {
		case .variation:
			return "variation"
		case .choirVariations:
			return "choirVariations"
		case .choirMP3:
			return "choirMP3"
		case .extractRange:
			return "extractRange"
		}
	}
	
	var usage: String {
		switch self {
		case .variation:
			return VariationArgs.usage
		case .choirVariations:
			return "<inputPath> <outputPath>?"
		case .choirMP3:
			return "<inputPath> <outputPath>?"
		case .extractRange:
			return "<inputPath> <outputPath> <firstMeasure> <lastMeasure>"
		}
	}
	
	func perform() {
		switch self {
		case .variation(let args):
			guard let args = args else {
				printUsage()
				return
			}
			performVariationAction(args: args)
		
		case .choirVariations(let inputPath, let outputPath):
			guard let inputPath = inputPath else {
				printUsage()
				return
			}
			performChoirVariationsAction(inputPath: inputPath, outputPath: outputPath)
		
		case .choirMP3(let inputPath, let outputPath):
			guard let inputPath = inputPath else {
				printUsage()
				return
			}
			performChoirMP3Action(inputPath: inputPath, outputPath: outputPath)
		
		case .extractRange(let inputPath, let outputPath, let firstMeasure, let lastMeasure):
			guard let inputPath = inputPath, let outputPath = outputPath else {
				printUsage()
				return
			}
			
			performExtractRangeAction(inputPath: inputPath, outputPath: outputPath, firstMeasure: firstMeasure, lastMeasure: lastMeasure)
		}
	}
	
	func printUsage() {
		fputs("Usage: ProcessMusicXML \(verb) \(usage)\n", stderr)
	}
}

