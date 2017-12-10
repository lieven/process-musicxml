//
//  Action.swift
//  ExplodeVoices
//
//  Created by Lieven Dekeyser on 10/12/2017.
//  Copyright © 2017 Plane Tree Software. All rights reserved.
//

import Foundation


enum Action {
	case variation(args: VariationArgs?)
	case satb(args: SATBArgs?)
	
	init?(args: [String]) {
		guard let verb = args[safe: 1] else {
			return nil
		}
		
		switch verb {
		case "variation":
			self = .variation(args: VariationArgs(args: Array(args[2...])))
		case "satb":
			self = .satb(args: SATBArgs(args: Array(args[2...])))
		default:
			return nil
		}
		
	}
	
	var verb: String {
		switch self {
		case .variation:
			return "variation"
		case .satb:
			return "satb"
		}
	}
	
	var usage: String {
		switch self {
		case .variation:
			return VariationArgs.usage
		
		case .satb:
			return SATBArgs.usage
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
		
		case .satb(let args):
			guard let args = args else {
				printUsage()
				return
			}
			performSATBAction(args: args)
		}
	}
	
	func printUsage() {
		fputs("Usage: ExplodeVoices \(verb) \(usage)\n", stderr)
	}
	
	static let all: [Action] = [.variation(args: nil), .satb(args: nil)]
}

