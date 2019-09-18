//
//  MuseScoreMeasure.swift
//  ProcessMuseScore
//
//  Created by Lieven Dekeyser on 15/09/2018.
//

import Foundation

extension Array {
	subscript (safe index: Int) -> Element? {
		guard index >= 0, index < count else {
			return nil
		}
		return self[index]
	}
}

enum MuseScoreDurationType: String {
	case measure
	case half
	
	var duration: (Int, Int)? {
		switch self {
		case .measure:
			return (1, 1)
		case .half:
			return (1, 2)
		}
	}
}

public class MuseScoreVoiceElement: ManagedXMLElement {
	public enum ElementType: String {
		case chord = "Chord"
		case rest = "Rest"
	}

	public let element: XMLElement
	public let type: ElementType
	
	required public init?(element: XMLElement) {
		guard let name = element.name, let type = ElementType(rawValue: name) else {
			return nil
		}
		self.element = element
		self.type = type
	}
	
	var durationTypeString: String? {
		return element.getStringValue(child: "durationType")
	}
	
	var durationType: MuseScoreDurationType? {
		guard let durationTypeString = durationTypeString else {
			return nil
		}
		
		return MuseScoreDurationType(rawValue: durationTypeString)
	}
	
	var durationString: String? {
		return element.getStringValue(child: "duration")
	}
	
	public var duration: (Int, Int)? {
		guard let durationString = durationString else {
			return durationType?.duration
		}
		
		let durationComponents = durationString.components(separatedBy: "/")
		guard durationComponents.count == 2 else {
			return nil
		}
		
		guard let denominator = Int(durationComponents[0]), let numerator = Int(durationComponents[1]) else {
			return nil
		}
		
		return (denominator, numerator)
	}
}


public class MuseScoreMeasure: ManagedXMLElement {
	public let element: XMLElement
	
	required public init?(element: XMLElement) {
		guard element.name == "Measure" else {
			return nil
		}
		self.element = element
	}
	
	var voices: [XMLElement] {
		return element.elements(forName: "voice")
	}
}

extension MuseScoreMeasure {
	func remove(voice: Int) {
		let voices = self.voices
		guard voice >= 0, voice < voices.count else {
			return
		}
		
		voices[voice].detach()
	}
	
	func keepOnly(voice: Int) {
		let voices = self.voices
		for i in 0..<voices.count {
			if i != voice {
				voices[i].detach()
			}
		}
	}
	
	func overwriteNotesWithThoseFrom(variation: MuseScoreMeasure, voice: Int) {
		guard let variationVoiceCopy = variation.voices[safe: voice]?.copy() as? XMLElement, let destinationVoiceElement = voices.first else {
			return
		}
		
		element.replaceChild(at: destinationVoiceElement.index, with: variationVoiceCopy)
		
		
		/* TODO: take <location> elements into account by measuring the position and duration of child elements
		let variationChildNodes = variationVoiceElement.children ?? [] 
		
		let variationElements: [MuseScoreVoiceElement] = variationChildNodes.compactMap { node in
			guard let element = node as? XMLElement else {
				return nil
			}
			
			return MuseScoreVoiceElement(element: element)
		}
		*/
	
		/* TODO
		let variationElements = variation.childElements.filter { $0.voice == voice }
		childElements = childElements.filter { !$0.overlaps(with: variationElements) }
		childElements.append(contentsOf: variationElements.compactMap {
			let result = $0.copy()
			result?.element.changeVoice(to: "1")
			return result
		})*/
	}
}
