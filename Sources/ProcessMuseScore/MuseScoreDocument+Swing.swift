//
//  MuseScoreDocument+Swing.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 07/09/2018.
//

import Foundation


enum SwingType {
	case none
	case eighth(ratio: Int)
	case sixteenth(ratio: Int)
	
	var stringValue: String {
		switch self {
		case .none:
			return "No Swing"
		case .eighth(let ratio):
			return "Eighth Note (ratio: \(ratio))"
		case .sixteenth(let ratio):
			return "Sixteenth Note (ratio: \(ratio))"
		}
	}
}



fileprivate extension XMLElement {
	var swingUnit: String? {
		get {
			return getStringValue(child: "swingUnit")
		}
		set {
			set(child: "swingUnit", stringValue: newValue)
		}
	}
	
	var swingRatio: Int? {
		get {
			guard let stringValue = getStringValue(child: "swingRatio") else {
				return nil
			}
			return Int(stringValue)
		}
		set {
			let stringValue: String?
			if let value = newValue {
				stringValue = "\(value)"
			} else {
				stringValue = nil
			}
			set(child: "swingRatio", stringValue: stringValue)
		}
	}
}

extension MuseScoreDocument {
	var styleElement: XMLElement? {
		return scoreElement.elements(forName: "Style").first
	}
	
	var swingType: SwingType {
		get {
			guard let styleElement = styleElement else {
				return .none
			}
			
			guard let swingUnitString = styleElement.swingUnit else {
				return .none
			}
			
			let ratio = styleElement.swingRatio ?? 60
			
			switch swingUnitString {
			case "eighth":
				return .eighth(ratio: ratio)
			case "sixteenth":
				return .sixteenth(ratio: ratio)
			default:
				return .none
			}
		}
		set {
			guard let styleElement = styleElement else {
				return
			}
			switch newValue {
			case .none:
				styleElement.swingUnit = nil
				styleElement.swingRatio = nil
			case .eighth(let ratio):
				styleElement.swingUnit = "eighth"
				styleElement.swingRatio = ratio
			case .sixteenth(let ratio):
				styleElement.swingUnit = "sixteenth"
				styleElement.swingRatio = ratio
			}
		}
	}
}
